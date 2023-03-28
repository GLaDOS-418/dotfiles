/*
*   Copyright (c) 1996-2003, Darren Hiebert
*
*   This source code is released for free distribution under the terms of the
*   GNU General Public License version 2 or (at your option) any later version.
*
*   This module contains functions for parsing and scanning Vera
*   source files.
*/

/*
*   INCLUDE FILES
*/
#include "general.h"        /* must always come first */

#include <string.h>
#include <setjmp.h>

#include "debug.h"
#include "entry.h"
#include "cpreprocessor.h"
#include "keyword.h"
#include "options.h"
#include "parse.h"
#include "read.h"
#include "routines.h"
#include "selectors.h"
#include "xtag.h"

/*
*   MACROS
*/

#define activeToken(st)     ((st)->token [(int) (st)->tokenIndex])
#define parentDecl(st)      ((st)->parent == NULL ? \
                            DECL_NONE : (st)->parent->declaration)
#define isType(token,t)     (bool) ((token)->type == (t))
#define insideEnumBody(st)  ((st)->parent == NULL ? false : \
                            (bool) ((st)->parent->declaration == DECL_ENUM))
#define insideInterfaceBody(st) ((st)->parent == NULL ? false : \
                            (bool) ((st)->parent->declaration == DECL_INTERFACE))
#define isSignalDirection(token) (bool)(( (token)->keyword == KEYWORD_INPUT  ) ||\
					   ( (token)->keyword == KEYWORD_OUTPUT ) ||\
					   ( (token)->keyword == KEYWORD_INOUT  )  )

#define isOneOf(c,s)        (bool) (strchr ((s), (c)) != NULL)


/*
*   DATA DECLARATIONS
*/

enum { NumTokens = 3 };

typedef enum eException {
	ExceptionNone, ExceptionEOF, ExceptionFormattingError,
	ExceptionBraceFormattingError
} exception_t;

/*  Used to specify type of keyword.
 */
enum eKeywordId {
	KEYWORD_BAD_STATE, KEYWORD_BAD_TRANS,
	KEYWORD_BIND, KEYWORD_BIND_VAR, KEYWORD_BIT,
	KEYWORD_CLASS, KEYWORD_CLOCK,
	KEYWORD_CONSTRAINT, KEYWORD_COVERAGE_BLOCK, KEYWORD_COVERAGE_DEF,
	KEYWORD_ENUM, KEYWORD_EXTERN,
	KEYWORD_EXTENDS, KEYWORD_EVENT,
	KEYWORD_FUNCTION,
	KEYWORD_HDL_NODE,
	KEYWORD_INOUT, KEYWORD_INPUT, KEYWORD_INTEGER, KEYWORD_INTERFACE,
	KEYWORD_LOCAL,
	KEYWORD_M_BAD_STATE, KEYWORD_M_BAD_TRANS, KEYWORD_M_STATE, KEYWORD_M_TRANS,
	KEYWORD_NEWCOV,
	KEYWORD_NHOLD, KEYWORD_NSAMPLE,
	KEYWORD_OUTPUT,
	KEYWORD_PACKED, KEYWORD_PORT, KEYWORD_PHOLD,
	KEYWORD_PROGRAM, KEYWORD_PROTECTED, KEYWORD_PSAMPLE, KEYWORD_PUBLIC,
	KEYWORD_SHADOW, KEYWORD_STATE,
	KEYWORD_STATIC, KEYWORD_STRING,
	KEYWORD_TASK,
	KEYWORD_TRANS, KEYWORD_TRANSITION,
	KEYWORD_TYPEDEF,
	KEYWORD_VIRTUAL, KEYWORD_VOID
};
typedef int keywordId; /* to allow KEYWORD_NONE */

/*  Used to determine whether keyword is valid for the current language and
 *  what its ID is.
 */
typedef struct sKeywordDesc {
	const char *name;
	keywordId id;
} keywordDesc;

/*  Used for reporting the type of object parsed by nextToken ().
 */
typedef enum eTokenType {
	TOKEN_NONE,          /* none */
	TOKEN_ARGS,          /* a parenthetical pair and its contents */
	TOKEN_BRACE_CLOSE,
	TOKEN_BRACE_OPEN,
	TOKEN_COLON,         /* the colon character */
	TOKEN_COMMA,         /* the comma character */
	TOKEN_DOUBLE_COLON,  /* double colon indicates nested-name-specifier */
	TOKEN_KEYWORD,
	TOKEN_NAME,          /* an unknown name */
	TOKEN_PAREN_NAME,    /* a single name in parentheses */
	TOKEN_SEMICOLON,     /* the semicolon character */
	TOKEN_COUNT
} tokenType;

/*  This describes the scoping of the current statement.
 */
typedef enum eTagScope {
	SCOPE_GLOBAL,        /* no storage class specified */
	SCOPE_STATIC,        /* static storage class */
	SCOPE_EXTERN,        /* external storage class */
	SCOPE_TYPEDEF,       /* scoping depends upon context */
	SCOPE_COUNT
} tagScope;

typedef enum eDeclaration {
	DECL_NONE,
	DECL_BASE,           /* base type (default) */
	DECL_CLASS,
	DECL_ENUM,
	DECL_EVENT,
	DECL_FUNCTION,
	DECL_INTERFACE,
	DECL_PROGRAM,
	DECL_TASK,
	DECL_COUNT
} declType;

typedef enum eVisibilityType {
	ACCESS_UNDEFINED,
	ACCESS_LOCAL,
	ACCESS_PRIVATE,
	ACCESS_PROTECTED,
	ACCESS_PUBLIC,
	ACCESS_COUNT
} accessType;

/*  Information about the parent class of a member (if any).
 */
typedef struct sMemberInfo {
	accessType access;           /* access of current statement */
	accessType accessDefault;    /* access default for current statement */
} memberInfo;

typedef struct sTokenInfo {
	tokenType     type;
	keywordId     keyword;
	vString*      name;          /* the name of the token */
	unsigned long lineNumber;    /* line number of tag */
	MIOPos        filePosition;  /* file position of line containing name */
} tokenInfo;

typedef enum eImplementation {
	IMP_DEFAULT,
	IMP_VIRTUAL,
	IMP_PURE_VIRTUAL,
	IMP_COUNT
} impType;

/*  Describes the statement currently undergoing analysis.
 */
typedef struct sStatementInfo {
	tagScope	scope;
	declType	declaration;    /* specifier associated with TOKEN_SPEC */
	bool		gotName;        /* was a name parsed yet? */
	bool		haveQualifyingName;  /* do we have a name we are considering? */
	bool		gotParenName;   /* was a name inside parentheses parsed yet? */
	bool		gotArgs;        /* was a list of parameters parsed yet? */
	bool		isPointer;      /* is 'name' a pointer? */
	bool     inFunction;     /* are we inside of a function? */
	bool		assignment;     /* have we handled an '='? */
	bool		notVariable;    /* has a variable declaration been disqualified ? */
	impType		implementation; /* abstract or concrete implementation? */
	unsigned int tokenIndex;    /* currently active token */
	tokenInfo*	token [(int) NumTokens];
	tokenInfo*	context;        /* accumulated scope of current statement */
	tokenInfo*	blockName;      /* name of current block */
	memberInfo	member;         /* information regarding parent class/struct */
	vString*	parentClasses;  /* parent classes */
	struct sStatementInfo *parent;  /* statement we are nested within */
} statementInfo;

/*  Describes the type of tag being generated.
 */
typedef enum eTagType {
	TAG_UNDEFINED,
	TAG_CLASS,       /* class name */
	TAG_ENUM,        /* enumeration name */
	TAG_ENUMERATOR,  /* enumerator (enumeration value) */
	TAG_EVENT,       /* event */
	TAG_FUNCTION,    /* function definition */
	TAG_INTERFACE,   /* interface declaration */
	TAG_LOCAL,       /* local variable definition */
	TAG_MEMBER,      /* structure, class or interface member */
	TAG_PROGRAM,     /* program name */
	TAG_PROTOTYPE,   /* function prototype or declaration */
	TAG_SIGNAL,      /* signal name */
	TAG_TASK,        /* task name */
	TAG_TYPEDEF,     /* typedef name / D alias name */
	TAG_VARIABLE,    /* variable definition */
	TAG_EXTERN_VAR,  /* external variable declaration */
	TAG_LABEL,       /* goto label */
	TAG_COUNT        /* must be last */
} tagType;

typedef struct sParenInfo {
	bool isPointer;
	bool isParamList;
	bool isNameCandidate;
	bool invalidContents;
	bool nestedArgs;
	unsigned int parameterCount;
} parenInfo;

/*
*   DATA DEFINITIONS
*/

static jmp_buf Exception;

static langType Lang_vera;
static vString *Signature;
static bool CollectingSignature;

/* Number used to uniquely identify anonymous structs and unions. */
static int AnonymousID = 0;

#define COMMONK_UNDEFINED -1


/* Used to index into the VeraKinds table. */
typedef enum {
	VR_MACRO_UNDEF,
	VR_MACRO_CONDITION,
} veraMacroRole;

static roleDefinition VeraMacroRoles [] = {
	RoleTemplateUndef,
	RoleTemplateCondition,
};


typedef enum {
	VR_HEADER_SYSTEM,
	VR_HEADER_LOCAL,
} veraHeaderRole;

static roleDefinition VeraHeaderRoles [] = {
	RoleTemplateSystem,
	RoleTemplateLocal,
};

typedef enum {
	VK_UNDEFINED = COMMONK_UNDEFINED,
	VK_CLASS, VK_DEFINE, VK_ENUMERATOR, VK_FUNCTION,
	VK_ENUMERATION, VK_INTERFACE, VK_LOCAL, VK_MEMBER, VK_PROGRAM, VK_PROTOTYPE,
	VK_SIGNAL, VK_TASK, VK_TYPEDEF, VK_VARIABLE,
	VK_EXTERN_VARIABLE, VK_HEADER, VK_MACRO_PARAM,
} veraKind;

static kindDefinition VeraKinds [] = {
	{ true,  'c', "class",      "classes"},
	{ true,  'd', "macro",      "macro definitions",
	  .referenceOnly = false, ATTACH_ROLES(VeraMacroRoles)},
	{ true,  'e', "enumerator", "enumerators (values inside an enumeration)"},
	{ true,  'f', "function",   "function definitions"},
	{ true,  'g', "enum",       "enumeration names"},
	{ true,  'i', "interface",  "interfaces"},
	{ false, 'l', "local",      "local variables"},
	{ true,  'm', "member",     "class, struct, and union members"},
	{ true,  'p', "program",    "programs"},
	{ false, 'P', "prototype",  "function prototypes"},
	{ true,  's', "signal",     "signals"},
	{ true,  't', "task",       "tasks"},
	{ true,  'T', "typedef",    "typedefs"},
	{ true,  'v', "variable",   "variable definitions"},
	{ false, 'x', "externvar",  "external variable declarations"},
	{ true,  'h', "header",     "included header files",
	  .referenceOnly = true, ATTACH_ROLES(VeraHeaderRoles)},
	{ false, 'D', "macroParameter", "cpp macro parameters"},
};

static const keywordDesc KeywordTable [] = {
     { "bad_state",       KEYWORD_BAD_STATE,      },
     { "bad_trans",       KEYWORD_BAD_TRANS,      },
     { "bind",            KEYWORD_BIND,           },
     { "bind_var",        KEYWORD_BIND_VAR,       },
     { "bit",             KEYWORD_BIT,            },
     { "class",           KEYWORD_CLASS,          },
     { "CLOCK",           KEYWORD_CLOCK,          },
     { "constraint",      KEYWORD_CONSTRAINT,     },
     { "coverage_block",  KEYWORD_COVERAGE_BLOCK, },
     { "coverage_def",    KEYWORD_COVERAGE_DEF,   },
     { "enum",            KEYWORD_ENUM,           },
     { "event",           KEYWORD_EVENT,          },
     { "extends",         KEYWORD_EXTENDS,        },
     { "extern",          KEYWORD_EXTERN,         },
     { "function",        KEYWORD_FUNCTION,       },
     { "hdl_node",        KEYWORD_HDL_NODE,       },
     { "inout",           KEYWORD_INOUT,          },
     { "input",           KEYWORD_INPUT,          },
     { "integer",         KEYWORD_INTEGER,        },
     { "interface",       KEYWORD_INTERFACE,      },
     { "local",           KEYWORD_LOCAL,          },
     { "m_bad_state",     KEYWORD_M_BAD_STATE,    },
     { "m_bad_trans",     KEYWORD_M_BAD_TRANS,    },
     { "m_state",         KEYWORD_M_STATE,        },
     { "m_trans",         KEYWORD_M_TRANS,        },
     { "newcov",          KEYWORD_NEWCOV,         },
     { "NHOLD",           KEYWORD_NHOLD,          },
     { "NSAMPLE",         KEYWORD_NSAMPLE,        },
     { "output",          KEYWORD_OUTPUT,         },
     { "packed",          KEYWORD_PACKED,         },
     { "PHOLD",           KEYWORD_PHOLD,          },
     { "port",            KEYWORD_PORT,           },
     { "program",         KEYWORD_PROGRAM,        },
     { "protected",       KEYWORD_PROTECTED,      },
     { "PSAMPLE",         KEYWORD_PSAMPLE,        },
     { "public",          KEYWORD_PUBLIC,         },
     { "shadow",          KEYWORD_SHADOW,         },
     { "state",           KEYWORD_STATE,          },
     { "static",          KEYWORD_STATIC,         },
     { "string",          KEYWORD_STRING,         },
     { "task",            KEYWORD_TASK,           },
     { "trans",           KEYWORD_TRANS,          },
     { "transition",      KEYWORD_TRANSITION,     },
     { "typedef",         KEYWORD_TYPEDEF,        },
     { "virtual",         KEYWORD_VIRTUAL,        },
     { "void",            KEYWORD_VOID,           },
};

/*
*   FUNCTION PROTOTYPES
*/
static void createTags (const unsigned int nestLevel, statementInfo *const parent);

/*
*   FUNCTION DEFINITIONS
*/

/*
*   Token management
*/

static void initToken (tokenInfo* const token)
{
	token->type			= TOKEN_NONE;
	token->keyword		= KEYWORD_NONE;
	token->lineNumber	= getInputLineNumber ();
	token->filePosition	= getInputFilePosition ();
	vStringClear (token->name);
}

static void advanceToken (statementInfo* const st)
{
	if (st->tokenIndex >= (unsigned int) NumTokens - 1)
		st->tokenIndex = 0;
	else
		++st->tokenIndex;
	initToken (st->token [st->tokenIndex]);
}

static tokenInfo *prevToken (const statementInfo *const st, unsigned int n)
{
	unsigned int tokenIndex;
	unsigned int num = (unsigned int) NumTokens;
	Assert (n < num);
	tokenIndex = (st->tokenIndex + num - n) % num;
	return st->token [tokenIndex];
}

static void setToken (statementInfo *const st, const tokenType type)
{
	tokenInfo *token;
	token = activeToken (st);
	initToken (token);
	token->type = type;
}

static void retardToken (statementInfo *const st)
{
	if (st->tokenIndex == 0)
		st->tokenIndex = (unsigned int) NumTokens - 1;
	else
		--st->tokenIndex;
	setToken (st, TOKEN_NONE);
}

static tokenInfo *newToken (void)
{
	tokenInfo *const token = xMalloc (1, tokenInfo);
	token->name = vStringNew ();
	initToken (token);
	return token;
}

static void deleteToken (tokenInfo *const token)
{
	if (token != NULL)
	{
		vStringDelete (token->name);
		eFree (token);
	}
}

static const char *accessString (const accessType access)
{
	static const char *const names [] = {
		"?", "local", "private", "protected", "public"
	};
	Assert (ARRAY_SIZE (names) == ACCESS_COUNT);
	Assert ((int) access < ACCESS_COUNT);
	return names [(int) access];
}

/*
*   Debugging functions
*/

#ifdef DEBUG

#define boolString(c)   ((c) ? "true" : "false")

static const char *tokenString (const tokenType type)
{
	static const char *const names [] = {
		"none", "args", "}", "{", "colon", "comma", "double colon", "keyword",
		"name", "paren-name", "semicolon"
	};
	Assert (ARRAY_SIZE (names) == TOKEN_COUNT);
	Assert ((int) type < TOKEN_COUNT);
	return names [(int) type];
}

static const char *scopeString (const tagScope scope)
{
	static const char *const names [] = {
		"global", "static", "extern", "typedef"
	};
	Assert (ARRAY_SIZE (names) == SCOPE_COUNT);
	Assert ((int) scope < SCOPE_COUNT);
	return names [(int) scope];
}

static const char *declString (const declType declaration)
{
	static const char *const names [] = {
		"?", "base", "class", "enum", "event", "function",
		"interface",
		"program", "task"
	};
	Assert (ARRAY_SIZE (names) == DECL_COUNT);
	Assert ((int) declaration < DECL_COUNT);
	return names [(int) declaration];
}

static const char *keywordString (const keywordId keyword)
{
	const size_t count = ARRAY_SIZE (KeywordTable);
	const char *name = "none";
	size_t i;
	for (i = 0  ;  i < count  ;  ++i)
	{
		const keywordDesc *p = &KeywordTable [i];
		if (p->id == keyword)
		{
			name = p->name;
			break;
		}
	}
	return name;
}

static void CTAGS_ATTR_UNUSED pt (tokenInfo *const token)
{
	if (isType (token, TOKEN_NAME))
		printf ("type: %-12s: %-13s   line: %lu\n",
			tokenString (token->type), vStringValue (token->name),
			token->lineNumber);
	else if (isType (token, TOKEN_KEYWORD))
		printf ("type: %-12s: %-13s   line: %lu\n",
			tokenString (token->type), keywordString (token->keyword),
			token->lineNumber);
	else
		printf ("type: %-12s                  line: %lu\n",
			tokenString (token->type), token->lineNumber);
}

static void CTAGS_ATTR_UNUSED ps (statementInfo *const st)
{
#define P	"[%-7u]"
	static unsigned int id = 0;
	unsigned int i;
	printf (P"scope: %s   decl: %s   gotName: %s   gotParenName: %s\n", id,
		scopeString (st->scope), declString (st->declaration),
		boolString (st->gotName), boolString (st->gotParenName));
	printf (P"haveQualifyingName: %s\n", id, boolString (st->haveQualifyingName));
	printf (P"access: %s   default: %s\n", id, accessString (st->member.access),
		accessString (st->member.accessDefault));
	printf (P"token  : ", id);
	pt (activeToken (st));
	for (i = 1  ;  i < (unsigned int) NumTokens  ;  ++i)
	{
		printf (P"prev %u : ", id, i);
		pt (prevToken (st, i));
	}
	printf (P"context: ", id);
	pt (st->context);
	id++;
#undef P
}

#endif

/*
*   Statement management
*/

static bool isContextualKeyword (const tokenInfo *const token)
{
	bool result;
	switch (token->keyword)
	{
		case KEYWORD_CLASS:
		case KEYWORD_ENUM:
		case KEYWORD_INTERFACE:
			result = true;
			break;

		default: result = false; break;
	}
	return result;
}

static bool isContextualStatement (const statementInfo *const st)
{
	bool result = false;
	if (st != NULL) switch (st->declaration)
	{
		case DECL_CLASS:
		case DECL_ENUM:
		case DECL_INTERFACE:
			result = true;
			break;

		default: result = false; break;
	}
	return result;
}

static bool isMember (const statementInfo *const st)
{
	bool result;
	if (isType (st->context, TOKEN_NAME))
		result = true;
	else
		result = (bool)
			(st->parent != NULL && isContextualStatement (st->parent));
	return result;
}

static void initMemberInfo (statementInfo *const st)
{
	accessType accessDefault = ACCESS_UNDEFINED;
	if (st->parent != NULL) switch (st->parent->declaration)
	{
		case DECL_ENUM:
			accessDefault = ACCESS_UNDEFINED;
			break;

		case DECL_CLASS:
			accessDefault = ACCESS_PRIVATE;
			break;

		case DECL_INTERFACE:
			accessDefault = ACCESS_PUBLIC;
			break;

		default: break;
	}
	st->member.accessDefault = accessDefault;
	st->member.access		 = accessDefault;
}

static void reinitStatement (statementInfo *const st, const bool partial)
{
	unsigned int i;

	if (! partial)
	{
		st->scope = SCOPE_GLOBAL;
		if (isContextualStatement (st->parent))
			st->declaration = DECL_BASE;
		else
			st->declaration = DECL_NONE;
	}
	st->gotParenName	= false;
	st->isPointer		= false;
	st->inFunction		= false;
	st->assignment		= false;
	st->notVariable		= false;
	st->implementation	= IMP_DEFAULT;
	st->gotArgs			= false;
	st->gotName			= false;
	st->haveQualifyingName = false;
	st->tokenIndex		= 0;

	if (st->parent != NULL)
		st->inFunction = st->parent->inFunction;

	for (i = 0  ;  i < (unsigned int) NumTokens  ;  ++i)
		initToken (st->token [i]);

	initToken (st->context);

	/*	Keep the block name, so that a variable following after a comma will
	 *	still have the structure name.
	 */
	if (! partial)
		initToken (st->blockName);

	vStringClear (st->parentClasses);

	/*  Init member info.
	 */
	if (! partial)
		st->member.access = st->member.accessDefault;
}

static void initStatement (statementInfo *const st, statementInfo *const parent)
{
	st->parent = parent;
	initMemberInfo (st);
	reinitStatement (st, false);
}

/*
*   Tag generation functions
*/
#define veraTagKind(type) veraTagKindFull(type, true)
#define veraTagKindNoAssert(type) veraTagKindFull(type, false)
static veraKind veraTagKindFull (const tagType type, bool with_assert) {
	veraKind result = VK_UNDEFINED;
	switch (type)
	{
		case TAG_CLASS:      result = VK_CLASS;           break;
		case TAG_ENUM:       result = VK_ENUMERATION;     break;
		case TAG_ENUMERATOR: result = VK_ENUMERATOR;      break;
		case TAG_FUNCTION:   result = VK_FUNCTION;        break;
		case TAG_INTERFACE:  result = VK_INTERFACE;       break;
		case TAG_LOCAL:      result = VK_LOCAL;           break;
		case TAG_MEMBER:     result = VK_MEMBER;          break;
		case TAG_PROGRAM:    result = VK_PROGRAM;         break;
		case TAG_PROTOTYPE:  result = VK_PROTOTYPE;       break;
		case TAG_SIGNAL:     result = VK_SIGNAL;          break;
		case TAG_TASK:       result = VK_TASK;            break;
		case TAG_TYPEDEF:    result = VK_TYPEDEF;         break;
		case TAG_VARIABLE:   result = VK_VARIABLE;        break;
		case TAG_EXTERN_VAR: result = VK_EXTERN_VARIABLE; break;

		default: if (with_assert) Assert ("Bad Vera tag type" == NULL); break;
	}
	return result;
}

static int kindIndexForType (const tagType type)
{
	return veraTagKind (type);
}

static const char *tagName (const tagType type)
{
	return VeraKinds [veraTagKind (type)].name;
}

static bool includeTag (const tagType type, const bool isFileScope)
{
	bool result;
	int k = COMMONK_UNDEFINED;

	if (isFileScope && !isXtagEnabled(XTAG_FILE_SCOPE))
		return false;

	k = veraTagKindNoAssert (type);
	if (k == COMMONK_UNDEFINED)
		result = false;
	else
		result = isInputLanguageKindEnabled (k);

	return result;
}

static tagType declToTagType (const declType declaration)
{
	tagType type = TAG_UNDEFINED;

	switch (declaration)
	{
		case DECL_CLASS:        type = TAG_CLASS;       break;
		case DECL_ENUM:         type = TAG_ENUM;        break;
		case DECL_EVENT:        type = TAG_EVENT;       break;
		case DECL_FUNCTION:     type = TAG_FUNCTION;    break;
		case DECL_INTERFACE:    type = TAG_INTERFACE;   break;
		case DECL_PROGRAM:      type = TAG_PROGRAM;     break;
		case DECL_TASK:         type = TAG_TASK;        break;

		default: Assert ("Unexpected declaration" == NULL); break;
	}
	return type;
}

static const char* accessField (const statementInfo *const st)
{
	const char* result = NULL;
	if (st->member.access != ACCESS_UNDEFINED)
		result = accessString (st->member.access);
	return result;
}

static void addOtherFields (tagEntryInfo* const tag, const tagType type,
							const statementInfo *const st,
							vString *const scope, vString *const typeRef)
{
	/*  For selected tag types, append an extension flag designating the
	 *  parent object in which the tag is defined.
	 */
	switch (type)
	{
		default: break;

		case TAG_FUNCTION:
		case TAG_PROTOTYPE:
			if (vStringLength (Signature) > 0)
				tag->extensionFields.signature = vStringValue (Signature);
		case TAG_CLASS:
		case TAG_ENUM:
		case TAG_ENUMERATOR:
		case TAG_EVENT:
		case TAG_INTERFACE:
		case TAG_MEMBER:
		case TAG_SIGNAL:
		case TAG_TASK:
		case TAG_TYPEDEF:
			if (vStringLength (scope) > 0  &&  isMember (st))
			{
				tagType ptype;

				if (isType (st->context, TOKEN_NAME))
				{
					tag->extensionFields.scopeKindIndex = kindIndexForType (TAG_CLASS);
					tag->extensionFields.scopeName = vStringValue (scope);
				}
				else if ((ptype = declToTagType (parentDecl (st))) &&
					 includeTag (ptype, isXtagEnabled(XTAG_FILE_SCOPE)))
				{
					tag->extensionFields.scopeKindIndex = kindIndexForType (ptype);
					tag->extensionFields.scopeName = vStringValue (scope);
				}
			}
			if ((type == TAG_CLASS  ||  type == TAG_INTERFACE) &&
				 vStringLength (st->parentClasses) > 0)
			{

				tag->extensionFields.inheritance =
						vStringValue (st->parentClasses);
			}
			if (isMember (st))
			{
				tag->extensionFields.access = accessField (st);
			}
			break;
	}

	/* Add typename info, type of the tag and name of struct/union/etc. */
	if ((type == TAG_TYPEDEF || type == TAG_VARIABLE || type == TAG_MEMBER)
			&& isContextualStatement(st))
	{
		char *p;

		tag->extensionFields.typeRef [0] =
						tagName (declToTagType (st->declaration));
		p = vStringValue (st->blockName->name);

		/*  If there was no {} block get the name from the token before the
		 *  name (current token is ';' or ',', previous token is the name).
		 */
		if (p == NULL || *p == '\0')
		{
			tokenInfo *const prev2 = prevToken (st, 2);
			if (isType (prev2, TOKEN_NAME))
				p = vStringValue (prev2->name);
		}

		/* Prepend the scope name if there is one. */
		if (vStringLength (scope) > 0)
		{
			vStringCopy(typeRef, scope);
			vStringCatS(typeRef, p);
			p = vStringValue (typeRef);
		}
		tag->extensionFields.typeRef [1] = p;
	}
}

static bool findScopeHierarchy (vString *const string, const statementInfo *const st)
{
	bool found = false;

	vStringClear (string);

	if (isType (st->context, TOKEN_NAME))
	{
		vStringCopy (string, st->context->name);
		found = true;
	}

	if (st->parent != NULL)
	{
		vString *temp = vStringNew ();
		const statementInfo *s;
		for (s = st->parent  ;  s != NULL  ;  s = s->parent)
		{
			if (isContextualStatement (s) ||
				s->declaration == DECL_PROGRAM)
			{
				found = true;
				vStringCopy (temp, string);
				vStringClear (string);
				if (isType (s->blockName, TOKEN_NAME))
				{
					if (isType (s->context, TOKEN_NAME) &&
					    vStringLength (s->context->name) > 0)
					{
						vStringCat (string, s->context->name);
					}
					vStringCat (string, s->blockName->name);
					vStringCat (string, temp);
				}
				else
				{
					/* Information for building scope string
					   is lacking. Maybe input is broken. */
					found = false;
				}
			}
		}
		vStringDelete (temp);
	}
	return found;
}

static void makeExtraTagEntry (const tagType type, tagEntryInfo *const e,
							   vString *const scope)
{
	if (isXtagEnabled(XTAG_QUALIFIED_TAGS)  &&
		scope != NULL  &&  vStringLength (scope) > 0)
	{
		vString *const scopedName = vStringNew ();

		if (type != TAG_ENUMERATOR)
			vStringCopy (scopedName, scope);
		else
		{
			/* remove last component (i.e. enumeration name) from scope */
			const char* const sc = vStringValue (scope);
			const char* colon = strrchr (sc, ':');
			if (colon != NULL)
			{
				while (*colon == ':'  &&  colon > sc)
					--colon;
				vStringNCopy (scopedName, scope, colon + 1 - sc);
			}
		}
		if (vStringLength (scopedName) > 0)
		{
			vStringCatS (scopedName, e->name);
			e->name = vStringValue (scopedName);
			markTagExtraBit (e, XTAG_QUALIFIED_TAGS);
			makeTagEntry (e);
		}
		vStringDelete (scopedName);
	}
}

static int makeTag (const tokenInfo *const token,
					 const statementInfo *const st,
					 bool isFileScope, const tagType type)
{
	int corkIndex = CORK_NIL;
	/*  Nothing is really of file scope when it appears in a header file.
	 */
	isFileScope = (bool) (isFileScope && ! isInputHeaderFile ());

	if (isType (token, TOKEN_NAME)  &&  vStringLength (token->name) > 0  &&
		includeTag (type, isFileScope))
	{
		vString *scope;
		vString *typeRef;
		bool isScopeBuilt;
		/* Use "typeRef" to store the typename from addOtherFields() until
		 * it's used in makeTagEntry().
		 */
		tagEntryInfo e;
		int kind;

		scope  = vStringNew ();
		typeRef = vStringNew ();

		kind  = kindIndexForType(type);
		initTagEntry (&e, vStringValue (token->name), kind);

		e.lineNumber	= token->lineNumber;
		e.filePosition	= token->filePosition;
		e.isFileScope	= isFileScope;
		if (e.isFileScope)
			markTagExtraBit (&e, XTAG_FILE_SCOPE);

		isScopeBuilt = findScopeHierarchy (scope, st);
		addOtherFields (&e, type, st, scope, typeRef);

		corkIndex = makeTagEntry (&e);
		if (isScopeBuilt)
			makeExtraTagEntry (type, &e, scope);
		vStringDelete (scope);
		vStringDelete (typeRef);
	}
	return corkIndex;
}

static bool isValidTypeSpecifier (const declType declaration)
{
	bool result;
	switch (declaration)
	{
		case DECL_BASE:
		case DECL_CLASS:
		case DECL_ENUM:
		case DECL_EVENT:
			result = true;
			break;

		default:
			result = false;
			break;
	}
	return result;
}

static int qualifyEnumeratorTag (const statementInfo *const st,
								 const tokenInfo *const nameToken)
{
	int corkIndex = CORK_NIL;
	if (isType (nameToken, TOKEN_NAME))
		corkIndex = makeTag (nameToken, st, true, TAG_ENUMERATOR);
	return corkIndex;
}

static int qualifyFunctionTag (const statementInfo *const st,
								const tokenInfo *const nameToken)
{
	int corkIndex = CORK_NIL;
	if (isType (nameToken, TOKEN_NAME))
	{
		tagType type;
		const bool isFileScope =
						(bool) (st->member.access == ACCESS_PRIVATE ||
						(!isMember (st)  &&  st->scope == SCOPE_STATIC));
		if (st->declaration == DECL_TASK)
			type = TAG_TASK;
		else
			type = TAG_FUNCTION;
		corkIndex = makeTag (nameToken, st, isFileScope, type);
	}
	return corkIndex;
}

static int qualifyFunctionDeclTag (const statementInfo *const st,
									const tokenInfo *const nameToken)
{
	int corkIndex = CORK_NIL;
	if (! isType (nameToken, TOKEN_NAME))
		;
	else if (st->scope == SCOPE_TYPEDEF)
		corkIndex = makeTag (nameToken, st, true, TAG_TYPEDEF);
	else if (isValidTypeSpecifier (st->declaration))
		corkIndex = makeTag (nameToken, st, true, TAG_PROTOTYPE);
	return corkIndex;
}

static int qualifyCompoundTag (const statementInfo *const st,
								const tokenInfo *const nameToken)
{
	int corkIndex = CORK_NIL;
	if (isType (nameToken, TOKEN_NAME))
	{
		const tagType type = declToTagType (st->declaration);

		if (type != TAG_UNDEFINED)
			corkIndex = makeTag (nameToken, st, false, type);
	}
	return corkIndex;
}

static int qualifyBlockTag (statementInfo *const st,
							 const tokenInfo *const nameToken)
{
	int corkIndex = CORK_NIL;
	switch (st->declaration)
	{

		case DECL_CLASS:
		case DECL_ENUM:
		case DECL_INTERFACE:
		case DECL_PROGRAM:
			corkIndex = qualifyCompoundTag (st, nameToken);
			break;
		default: break;
	}
	return corkIndex;
}

static int qualifyVariableTag (const statementInfo *const st,
								const tokenInfo *const nameToken)
{
	int corkIndex = CORK_NIL;
	/*	We have to watch that we do not interpret a declaration of the
	 *	form "struct tag;" as a variable definition. In such a case, the
	 *	token preceding the name will be a keyword.
	 */
	if (! isType (nameToken, TOKEN_NAME))
		;
	else if (st->scope == SCOPE_TYPEDEF)
		corkIndex = makeTag (nameToken, st, true, TAG_TYPEDEF);
	else if (st->declaration == DECL_EVENT)
		corkIndex = makeTag (nameToken, st, (bool) (st->member.access == ACCESS_PRIVATE),
							 TAG_EVENT);
	else if (isValidTypeSpecifier (st->declaration))
	{
		if (st->notVariable)
			;
		else if (isMember (st))
		{
			if (st->scope == SCOPE_GLOBAL  ||  st->scope == SCOPE_STATIC)
				corkIndex = makeTag (nameToken, st, true, TAG_MEMBER);
		}
		else
		{
			if (st->scope == SCOPE_EXTERN  ||  ! st->haveQualifyingName)
				corkIndex = makeTag (nameToken, st, false, TAG_EXTERN_VAR);
			else if (st->inFunction)
				corkIndex = makeTag (nameToken, st, (bool) (st->scope == SCOPE_STATIC),
									 TAG_LOCAL);
			else
				corkIndex = makeTag (nameToken, st, (bool) (st->scope == SCOPE_STATIC),
									 TAG_VARIABLE);
		}
	}
	return corkIndex;
}

/*
*   Parsing functions
*/


/*  Skip to the next non-white character.
 */
static int skipToNonWhite (void)
{
	bool found = false;
	int c;

#if 0
	do
		c = cppGetc ();
	while (cppIsspace (c));
#else
	while (1)
	{
		c = cppGetc ();
		if (cppIsspace (c))
			found = true;
		else
			break;
	}
	if (CollectingSignature && found)
		vStringPut (Signature, ' ');
#endif

	return c;
}

/*  Skips to the next brace in column 1. This is intended for cases where
 *  preprocessor constructs result in unbalanced braces.
 */
static void skipToFormattedBraceMatch (void)
{
	int c, next;

	c = cppGetc ();
	next = cppGetc ();
	while (c != EOF  &&  (c != '\n'  ||  next != '}'))
	{
		c = next;
		next = cppGetc ();
	}
}

/*  Skip to the matching character indicated by the pair string. If skipping
 *  to a matching brace and any brace is found within a different level of a
 *  #if conditional statement while brace formatting is in effect, we skip to
 *  the brace matched by its formatting. It is assumed that we have already
 *  read the character which starts the group (i.e. the first character of
 *  "pair").
 */
static void skipToMatch (const char *const pair)
{
	const bool braceMatching = (bool) (strcmp ("{}", pair) == 0);
	const bool braceFormatting = (bool) (cppIsBraceFormat () && braceMatching);
	const unsigned int initialLevel = cppGetDirectiveNestLevel ();
	const int begin = pair [0], end = pair [1];
	const unsigned long inputLineNumber = getInputLineNumber ();
	int matchLevel = 1;
	int c = '\0';

	while (matchLevel > 0  &&  (c = skipToNonWhite ()) != EOF)
	{
		if (CollectingSignature)
			vStringPut (Signature, c);
		if (c == begin)
		{
			++matchLevel;
			if (braceFormatting  &&  cppGetDirectiveNestLevel () != initialLevel)
			{
				skipToFormattedBraceMatch ();
				break;
			}
		}
		else if (c == end)
		{
			--matchLevel;
			if (braceFormatting  &&  cppGetDirectiveNestLevel () != initialLevel)
			{
				skipToFormattedBraceMatch ();
				break;
			}
		}
	}
	if (c == EOF)
	{
		verbose ("%s: failed to find match for '%c' at line %lu\n",
				getInputFileName (), begin, inputLineNumber);
		if (braceMatching)
			longjmp (Exception, (int) ExceptionBraceFormattingError);
		else
			longjmp (Exception, (int) ExceptionFormattingError);
	}
}

static keywordId analyzeKeyword (const char *const name)
{
	const keywordId id = (keywordId) lookupKeyword (name, getInputLanguage ());
	return id;
}

static void analyzeIdentifier (tokenInfo *const token)
{
	const char * name = vStringValue (token->name);

	vString * replacement = NULL;

	// C: check for ignored token
	// (FIXME: java doesn't support -I... but maybe it should?)
	const cppMacroInfo * macro = cppFindMacro(name);

	if(macro)
	{
		if(macro->hasParameterList)
		{
			// This old parser does not support macro parameters: we simply assume them to be empty
			int c = skipToNonWhite ();

			if (c == '(')
				skipToMatch ("()");
		}

		if(macro->replacements)
		{
			// There is a replacement: analyze it
			replacement = cppBuildMacroReplacement(macro,NULL,0);
			name = replacement ? vStringValue(replacement) : NULL;
		} else {
			// There is no replacement: just ignore
			name = NULL;
		}
	}

	if(!name)
	{
		initToken(token);
		if(replacement)
			vStringDelete(replacement);
		return;
	}

	token->keyword = analyzeKeyword (name);

	if (token->keyword == KEYWORD_NONE)
		token->type = TOKEN_NAME;
	else
		token->type = TOKEN_KEYWORD;

	if(replacement)
		vStringDelete(replacement);
}

static void readIdentifier (tokenInfo *const token, const int firstChar)
{
	vString *const name = token->name;
	int c = firstChar;
	bool first = true;

	initToken (token);

	do
	{
		vStringPut (name, c);
		if (CollectingSignature)
		{
			if (!first)
				vStringPut (Signature, c);
			first = false;
		}
		c = cppGetc ();
	} while (cppIsident (c));
	cppUngetc (c);        /* unget non-identifier character */

	analyzeIdentifier (token);
}

static void processName (statementInfo *const st)
{
	Assert (isType (activeToken (st), TOKEN_NAME));
	if (st->gotName  &&  st->declaration == DECL_NONE)
		st->declaration = DECL_BASE;
	st->gotName = true;
	st->haveQualifyingName = true;
}

static void copyToken (tokenInfo *const dest, const tokenInfo *const src)
{
	dest->type         = src->type;
	dest->keyword      = src->keyword;
	dest->filePosition = src->filePosition;
	dest->lineNumber   = src->lineNumber;
	vStringCopy (dest->name, src->name);
}

static void setAccess (statementInfo *const st, const accessType access)
{
	if (isMember (st))
	{
		st->member.access = access;
	}
}

static void addParentClass (statementInfo *const st, tokenInfo *const token)
{
	if (vStringLength (token->name) > 0  &&
		vStringLength (st->parentClasses) > 0)
	{
		vStringPut (st->parentClasses, ',');
	}
	vStringCat (st->parentClasses, token->name);
}

static void readParents (statementInfo *const st, const int qualifier)
{
	tokenInfo *const token = newToken ();
	tokenInfo *const parent = newToken ();
	int c;

	do
	{
		c = skipToNonWhite ();
		if (cppIsident1 (c))
		{
			readIdentifier (token, c);
			if (isType (token, TOKEN_NAME))
				vStringCat (parent->name, token->name);
			else
			{
				addParentClass (st, parent);
				initToken (parent);
			}
		}
		else if (c == qualifier)
			vStringPut (parent->name, c);
		else if (c == '<')
			skipToMatch ("<>");
		else if (isType (token, TOKEN_NAME))
		{
			addParentClass (st, parent);
			initToken (parent);
		}
	} while (c != '{'  &&  c != EOF);
	cppUngetc (c);
	deleteToken (parent);
	deleteToken (token);
}

static void processInterface (statementInfo *const st)
{
	st->declaration = DECL_INTERFACE;
}

static void checkIsClassEnum (statementInfo *const st, const declType decl)
{
	st->declaration = decl;
}

static void processToken (tokenInfo *const token, statementInfo *const st)
{
	switch ((int)token->keyword)        /* is it a reserved word? */
	{
		default: break;

		case KEYWORD_NONE:      processName (st);                       break;
		case KEYWORD_BIND:      st->declaration = DECL_BASE;            break;
		case KEYWORD_BIT:       st->declaration = DECL_BASE;            break;
		case KEYWORD_CLASS:     checkIsClassEnum (st, DECL_CLASS);      break;
		case KEYWORD_ENUM:      st->declaration = DECL_ENUM;            break;
		case KEYWORD_EXTENDS:   readParents (st, '.');
		                        setToken (st, TOKEN_NONE);              break;
		case KEYWORD_FUNCTION:  st->declaration = DECL_BASE;            break;
		case KEYWORD_INTEGER:   st->declaration = DECL_BASE;            break;
		case KEYWORD_INTERFACE: processInterface (st);                  break;
		case KEYWORD_LOCAL:     setAccess (st, ACCESS_LOCAL);           break;
		case KEYWORD_PROGRAM:   st->declaration = DECL_PROGRAM;         break;
		case KEYWORD_PROTECTED: setAccess (st, ACCESS_PROTECTED);       break;
		case KEYWORD_PUBLIC:    setAccess (st, ACCESS_PUBLIC);          break;
		case KEYWORD_STRING:    st->declaration = DECL_BASE;            break;
		case KEYWORD_TASK:      st->declaration = DECL_TASK;            break;
		case KEYWORD_VOID:      st->declaration = DECL_BASE;            break;
		case KEYWORD_VIRTUAL:   st->implementation = IMP_VIRTUAL;       break;

		case KEYWORD_EVENT:
			break;

		case KEYWORD_TYPEDEF:
			reinitStatement (st, false);
			st->scope = SCOPE_TYPEDEF;
			break;

		case KEYWORD_EXTERN:
			reinitStatement (st, false);
			st->scope = SCOPE_EXTERN;
			st->declaration = DECL_BASE;
			break;

		case KEYWORD_STATIC:
			reinitStatement (st, false);
			st->scope = SCOPE_STATIC;
			st->declaration = DECL_BASE;
			break;
	}
}

/*
*   Parenthesis handling functions
*/

static void restartStatement (statementInfo *const st)
{
	tokenInfo *const save = newToken ();
	tokenInfo *token = activeToken (st);

	copyToken (save, token);
	DebugStatement ( if (debug (DEBUG_PARSE)) printf ("<ES>");)
	reinitStatement (st, false);
	token = activeToken (st);
	copyToken (token, save);
	deleteToken (save);
	processToken (token, st);
}

/*  Skips over a mem-initializer-list of a ctor-initializer, defined as:
 *
 *  mem-initializer-list:
 *    mem-initializer, mem-initializer-list
 *
 *  mem-initializer:
 *    [::] [nested-name-spec] class-name (...)
 *    identifier
 */
static void skipMemIntializerList (tokenInfo *const token)
{
	int c;

	do
	{
		c = skipToNonWhite ();
		while (cppIsident1 (c)  ||  c == ':')
		{
			if (c != ':')
				readIdentifier (token, c);
			c = skipToNonWhite ();
		}
		if (c == '<')
		{
			skipToMatch ("<>");
			c = skipToNonWhite ();
		}
		if (c == '(')
		{
			skipToMatch ("()");
			c = skipToNonWhite ();
		}
	} while (c == ',');
	cppUngetc (c);
}

static void skipMacro (statementInfo *const st)
{
	tokenInfo *const prev2 = prevToken (st, 2);

	if (isType (prev2, TOKEN_NAME))
		retardToken (st);
	skipToMatch ("()");
}

/*  Skips over characters following the parameter list.
 *  Originally written for C++, may contain unnecessary stuff.
 *
 *  C#:
 *    public C(double x) : base(x) {}
 */
static bool skipPostArgumentStuff (
		statementInfo *const st, parenInfo *const info)
{
	tokenInfo *const token = activeToken (st);
	unsigned int parameters = info->parameterCount;
	unsigned int elementCount = 0;
	bool restart = false;
	bool end = false;
	int c = skipToNonWhite ();

	do
	{
		switch (c)
		{
		case ')':                               break;
		case ':': skipMemIntializerList (token);break;  /* ctor-initializer */
		case '[': skipToMatch ("[]");           break;
		case '=': cppUngetc (c); end = true;    break;
		case '{': cppUngetc (c); end = true;    break;
		case '}': cppUngetc (c); end = true;    break;

		case '(':
			if (elementCount > 0)
				++elementCount;
			skipToMatch ("()");
			break;

		case ';':
			if (parameters == 0  ||  elementCount < 2)
			{
				cppUngetc (c);
				end = true;
			}
			else if (--parameters == 0)
				end = true;
			break;

		default:
			if (cppIsident1 (c))
			{
				readIdentifier (token, c);
				switch (token->keyword)
				{
				case KEYWORD_CLASS:
				case KEYWORD_EXTERN:
				case KEYWORD_NEWCOV:
				case KEYWORD_PROTECTED:
				case KEYWORD_PUBLIC:
				case KEYWORD_STATIC:
				case KEYWORD_TYPEDEF:
				case KEYWORD_VIRTUAL:
					/* Never allowed within parameter declarations. */
					restart = true;
					end = true;
					break;

				default:
					if (isType (token, TOKEN_NONE))
						;
					else
					{
						/*  If we encounter any other identifier immediately
						 *  following an empty parameter list, this is almost
						 *  certainly one of those Microsoft macro "thingies"
						 *  that the automatic source code generation sticks
						 *  in. Terminate the current statement.
						 */
						restart = true;
						end = true;
					}
					break;
				}
			}
		}
		if (! end)
		{
			c = skipToNonWhite ();
			if (c == EOF)
				end = true;
		}
	} while (! end);

	if (restart)
		restartStatement (st);
	else
		setToken (st, TOKEN_NONE);

	return (bool) (c != EOF);
}

static void analyzePostParens (statementInfo *const st, parenInfo *const info)
{
	const unsigned long inputLineNumber = getInputLineNumber ();
	int c = skipToNonWhite ();

	cppUngetc (c);
	if (isOneOf (c, "{;,="))
		;
	else {
		if (! skipPostArgumentStuff (st, info))
		{
			verbose (
				"%s: confusing argument declarations beginning at line %lu\n",
				getInputFileName (), inputLineNumber);
			longjmp (Exception, (int) ExceptionFormattingError);
		}
	}
}

static void processAngleBracket (void)
{
	int c = cppGetc ();
	if (c == '>') {
		/* already found match for template */
	} else if (c == '<') {
		/* skip "<<" or "<<=". */
		c = cppGetc ();
		if (c != '=') {
			cppUngetc (c);
		}
	} else {
		cppUngetc (c);
	}
}

static int parseParens (statementInfo *const st, parenInfo *const info)
{
	tokenInfo *const token = activeToken (st);
	unsigned int identifierCount = 0;
	unsigned int depth = 1;
	bool firstChar = true;
	int nextChar = '\0';

	CollectingSignature = true;
	vStringClear (Signature);
	vStringPut (Signature, '(');
	info->parameterCount = 1;
	do
	{
		int c = skipToNonWhite ();
		vStringPut (Signature, c);

		switch (c)
		{
			case '^':
				break;

			case '&':
			case '*':
				info->isPointer = true;
				if (identifierCount == 0)
					info->isParamList = false;
				initToken (token);
				break;

			case ':':
				break;

			case '.':
				info->isNameCandidate = false;
				c = cppGetc ();
				if (c != '.')
					cppUngetc (c);
				else
				{
					c = cppGetc ();
					if (c != '.')
						cppUngetc (c);
					else
						vStringCatS (Signature, "..."); /* variable arg list */
				}
				break;

			case ',':
				info->isNameCandidate = false;
				break;

			case '=':
				info->isNameCandidate = false;
				if (firstChar)
				{
					info->isParamList = false;
					skipMacro (st);
					depth = 0;
				}
				break;

			case '[':
				skipToMatch ("[]");
				break;

			case '<':
				processAngleBracket ();
				break;

			case ')':
				if (firstChar)
					info->parameterCount = 0;
				--depth;
				break;

			case '(':
				if (firstChar)
				{
					info->isNameCandidate = false;
					cppUngetc (c);
					vStringClear (Signature);
					skipMacro (st);
					depth = 0;
					vStringChop (Signature);
				}
				else if (isType (token, TOKEN_PAREN_NAME))
				{
					c = skipToNonWhite ();
					if (c == '*')        /* check for function pointer */
					{
						skipToMatch ("()");
						c = skipToNonWhite ();
						if (c == '(')
							skipToMatch ("()");
						else
							cppUngetc (c);
					}
					else
					{
						cppUngetc (c);
						cppUngetc ('(');
						info->nestedArgs = true;
					}
				}
				else
					++depth;
				break;

			default:
				if (cppIsident1 (c))
				{
					readIdentifier (token, c);
					if (isType (token, TOKEN_NAME)  &&  info->isNameCandidate)
						token->type = TOKEN_PAREN_NAME;
					else if (isType (token, TOKEN_KEYWORD))
					{
						info->isNameCandidate = false;
					}
				}
				else
				{
					info->isParamList     = false;
					info->isNameCandidate = false;
					info->invalidContents = true;
				}
				break;
		}
		firstChar = false;
	} while (! info->nestedArgs  &&  depth > 0  &&  info->isNameCandidate);

	if (! info->nestedArgs) while (depth > 0)
	{
		skipToMatch ("()");
		--depth;
	}

	if (! info->isNameCandidate)
		initToken (token);

	CollectingSignature = false;
	return nextChar;
}

static void initParenInfo (parenInfo *const info)
{
	info->isPointer				= false;
	info->isParamList			= true;
	info->isNameCandidate		= true;
	info->invalidContents		= false;
	info->nestedArgs			= false;
	info->parameterCount		= 0;
}

static void analyzeParens (statementInfo *const st)
{
	tokenInfo *const prev = prevToken (st, 1);

	if (st->inFunction && !st->assignment)
		st->notVariable = true;

	if (! isType (prev, TOKEN_NONE))  /* in case of ignored enclosing macros */
	{
		tokenInfo *const token = activeToken (st);
		parenInfo info;
		int c;

		initParenInfo (&info);
		parseParens (st, &info);
		c = skipToNonWhite ();
		cppUngetc (c);
		if (info.invalidContents)
		{
			/* FIXME: This breaks parsing of variable instantiations that have
			   constants as parameters: Type var(0) or Type var("..."). */
			reinitStatement (st, false);
		}
		else if (info.isNameCandidate  &&  isType (token, TOKEN_PAREN_NAME)  &&
				 ! st->gotParenName  &&
				 (! info.isParamList || ! st->haveQualifyingName  ||
				  c == '('  ||
				  (c == '='  &&  st->implementation != IMP_VIRTUAL) ||
				  (st->declaration == DECL_NONE  &&  isOneOf (c, ",;"))))
		{
			token->type = TOKEN_NAME;
			processName (st);
			st->gotParenName = true;
			if (! (c == '('  &&  info.nestedArgs))
				st->isPointer = info.isPointer;
		}
		else if (! st->gotArgs  &&  info.isParamList)
		{
			st->gotArgs = true;
			setToken (st, TOKEN_ARGS);
			advanceToken (st);
			if (st->scope != SCOPE_TYPEDEF)
				analyzePostParens (st, &info);
		}
		else
			setToken (st, TOKEN_NONE);
	}
}

/*
*   Token parsing functions
*/

static void addContext (statementInfo *const st, const tokenInfo* const token)
{
	if (isType (token, TOKEN_NAME))
	{
		vStringCat (st->context->name, token->name);
		st->context->type = TOKEN_NAME;
	}
}

static void processColon (statementInfo *const st)
{
	int c = skipToNonWhite ();
	const bool doubleColon = (bool) (c == ':');

	if (doubleColon)
	{
		setToken (st, TOKEN_DOUBLE_COLON);
		st->haveQualifyingName = false;
	}
	else
	{
		const tokenInfo *const prev  = prevToken (st, 1);
		cppUngetc (c);
		if (st->parent != NULL)
		{
			makeTag (prev, st, false, TAG_LABEL);
			reinitStatement (st, false);
		}
	}
}

/*  Skips over any initializing value which may follow an '=' character in a
 *  variable definition.
 */
static int skipInitializer (statementInfo *const st)
{
	bool done = false;
	int c;

	while (! done)
	{
		c = skipToNonWhite ();

		if (c == EOF)
			longjmp (Exception, (int) ExceptionFormattingError);
		else switch (c)
		{
			case ',':
			case ';': done = true; break;

			case '0':
				if (st->implementation == IMP_VIRTUAL)
					st->implementation = IMP_PURE_VIRTUAL;
				break;

			case '[': skipToMatch ("[]"); break;
			case '(': skipToMatch ("()"); break;
			case '{': skipToMatch ("{}"); break;
			case '<': processAngleBracket(); break;

			case '}':
				if (insideEnumBody (st))
					done = true;
				else if (! cppIsBraceFormat ())
				{
					verbose ("%s: unexpected closing brace at line %lu\n",
							getInputFileName (), getInputLineNumber ());
					longjmp (Exception, (int) ExceptionBraceFormattingError);
				}
				break;

			default: break;
		}
	}
	return c;
}

static void processInitializer (statementInfo *const st)
{
	const bool inEnumBody = insideEnumBody (st);
	int c = cppGetc ();

	if (c != '=')
	{
		cppUngetc (c);
		c = skipInitializer (st);
		st->assignment = true;
		if (c == ';')
			setToken (st, TOKEN_SEMICOLON);
		else if (c == ',')
			setToken (st, TOKEN_COMMA);
		else if (c == '}'  &&  inEnumBody)
		{
			cppUngetc (c);
			setToken (st, TOKEN_COMMA);
		}
		if (st->scope == SCOPE_EXTERN)
			st->scope = SCOPE_GLOBAL;
	}
}

static void parseIdentifier (statementInfo *const st, const int c)
{
	tokenInfo *const token = activeToken (st);

	readIdentifier (token, c);
	if (! isType (token, TOKEN_NONE))
		processToken (token, st);
}

static void parseGeneralToken (statementInfo *const st, const int c)
{
	const tokenInfo *const prev = prevToken (st, 1);

	if (cppIsident1 (c))
	{

		parseIdentifier (st, c);
		if (isType (st->context, TOKEN_NAME) &&
			isType (activeToken (st), TOKEN_NAME) && isType (prev, TOKEN_NAME))
		{
			initToken (st->context);
		}
	}
	else if (c == '.' || c == '-')
	{
		if (! st->assignment)
			st->notVariable = true;
		if (c == '-')
		{
			int c2 = cppGetc ();
			if (c2 != '>')
				cppUngetc (c2);
		}
	}
	else if (c == '!' || c == '>')
	{
		int c2 = cppGetc ();
		if (c2 != '=')
			cppUngetc (c2);
	}
	else if (c == STRING_SYMBOL) {
		setToken(st, TOKEN_NONE);
	}
}

/*  Reads characters from the pre-processor and assembles tokens, setting
 *  the current statement state.
 */
static void nextToken (statementInfo *const st)
{
	tokenInfo *token;
	do
	{
		int c = skipToNonWhite ();
		switch (c)
		{
			case EOF: longjmp (Exception, (int) ExceptionEOF);  break;
			case '(': analyzeParens (st);                       break;
			case '<': processAngleBracket ();                   break;
			case '*': st->haveQualifyingName = false;           break;
			case ',': setToken (st, TOKEN_COMMA);               break;
			case ':': processColon (st);                        break;
			case ';': setToken (st, TOKEN_SEMICOLON);           break;
			case '=': processInitializer (st);                  break;
			case '[': skipToMatch ("[]");                       break;
			case '{': setToken (st, TOKEN_BRACE_OPEN);          break;
			case '}': setToken (st, TOKEN_BRACE_CLOSE);         break;
			default:  parseGeneralToken (st, c);                break;
		}
		token = activeToken (st);
	} while (isType (token, TOKEN_NONE));
}

/*
*   Scanning support functions
*/

static statementInfo *CurrentStatement = NULL;

static statementInfo *newStatement (statementInfo *const parent)
{
	statementInfo *const st = xMalloc (1, statementInfo);
	unsigned int i;

	for (i = 0  ;  i < (unsigned int) NumTokens  ;  ++i)
		st->token [i] = newToken ();

	st->context = newToken ();
	st->blockName = newToken ();
	st->parentClasses = vStringNew ();

	initStatement (st, parent);
	CurrentStatement = st;

	return st;
}

static void deleteStatement (void)
{
	statementInfo *const st = CurrentStatement;
	statementInfo *const parent = st->parent;
	unsigned int i;

	for (i = 0  ;  i < (unsigned int) NumTokens  ;  ++i)
	{
		deleteToken (st->token [i]);       st->token [i] = NULL;
	}
	deleteToken (st->blockName);           st->blockName = NULL;
	deleteToken (st->context);             st->context = NULL;
	vStringDelete (st->parentClasses);     st->parentClasses = NULL;
	eFree (st);
	CurrentStatement = parent;
}

static void deleteAllStatements (void)
{
	while (CurrentStatement != NULL)
		deleteStatement ();
}

static bool isStatementEnd (const statementInfo *const st)
{
	const tokenInfo *const token = activeToken (st);
	bool isEnd;

	if (isType (token, TOKEN_SEMICOLON))
		isEnd = true;
	else if (isType (token, TOKEN_BRACE_CLOSE))
		isEnd = ! isContextualStatement (st);
	else
		isEnd = false;

	return isEnd;
}

static void checkStatementEnd (statementInfo *const st, int corkIndex)
{
	const tokenInfo *const token = activeToken (st);

	tagEntryInfo *e = getEntryInCorkQueue (corkIndex);
	if (e)
		e->extensionFields.endLine = token->lineNumber;

	if (isType (token, TOKEN_COMMA))
		reinitStatement (st, true);
	else if (isStatementEnd (st))
	{
		DebugStatement ( if (debug (DEBUG_PARSE)) printf ("<ES>"); )
		reinitStatement (st, false);
		cppEndStatement ();
	}
	else
	{
		cppBeginStatement ();
		advanceToken (st);
	}
}

static void nest (statementInfo *const st, const unsigned int nestLevel)
{
	switch (st->declaration)
	{
		case DECL_CLASS:
		case DECL_ENUM:
		case DECL_INTERFACE:
			createTags (nestLevel, st);
			break;

		case DECL_FUNCTION:
		case DECL_TASK:
			st->inFunction = true;
			/* fall through */
		default:
			if (includeTag (TAG_LOCAL, false) || includeTag (TAG_LABEL, false))
				createTags (nestLevel, st);
			else
				skipToMatch ("{}");
			break;
	}
	advanceToken (st);
	setToken (st, TOKEN_BRACE_CLOSE);
}

static int tagCheck (statementInfo *const st)
{
	const tokenInfo *const token = activeToken (st);
	const tokenInfo *const prev  = prevToken (st, 1);
	const tokenInfo *const prev2 = prevToken (st, 2);
	int corkIndex = CORK_NIL;

	switch (token->type)
	{
		case TOKEN_NAME:
			if (insideEnumBody (st))
				corkIndex = qualifyEnumeratorTag (st, token);
			if (insideInterfaceBody (st))
			{
				/* Quoted from
				   http://www.asic-world.com/vera/hdl1.html#Interface_Declaration
				   ------------------------------------------------
				   interface interface_name
				   {
				   signal_direction [signal_width] signal_name signal_type
				   [skew] [depth value][vca q_value][force][hdl_node "hdl_path"];
				   }
				   Where
				   signal_direction : This can be one of the following
				        input : ...
				        output : ...
				        inout : ...
				   signal_width : The signal_width is a range specifying the width of
				                  a vector signal. It must be in the form [msb:lsb].
						  Interface signals can have any integer lsb value,
						  even a negative value. The default width is 1.
				   signal_name : The signal_name identifies the signal being defined.
				                 It is the Vera name for the HDL signal being connected.
				   signal_type : There are many signals types, most commonly used one are
					NHOLD : ...
					PHOLD : ...
					PHOLD NHOLD : ...
					NSAMPLE : ...
					PSAMPLE : ...
					PSAMPLE NSAMPLE : ...
					CLOCK : ...
					PSAMPLE PHOLD : ...
					NSAMPLE NHOLD : ...
					PSAMPLE PHOLD NSAMPLE NHOLD : ...
				   ------------------------------------------------
				   We want to capture "signal_name" here.
				*/
				if (( isType (prev, TOKEN_KEYWORD)
				      && isSignalDirection(prev) ) ||
				    ( isType (prev2, TOKEN_KEYWORD)
				      && isSignalDirection(prev) ))
					corkIndex = makeTag (token, st, false, TAG_SIGNAL);
			}
			break;
		case TOKEN_BRACE_OPEN:
			if (isType (prev, TOKEN_ARGS))
			{
				if (st->haveQualifyingName)
				{
					if (isType (prev2, TOKEN_NAME))
						copyToken (st->blockName, prev2);

					corkIndex = qualifyFunctionTag (st, prev2);
				}
			}
			else if (isContextualStatement (st) ||
					st->declaration == DECL_PROGRAM)
			{
				const tokenInfo *name_token = prev;

				if (isType (name_token, TOKEN_NAME))
					copyToken (st->blockName, name_token);
				else
				{
					/*  For an anonymous struct or union we use a unique ID
					 *  a number, so that the members can be found.
					 */
					char buf [20];  /* length of "_anon" + digits  + null */
					sprintf (buf, "__anon%d", ++AnonymousID);
					vStringCopyS (st->blockName->name, buf);
					st->blockName->type = TOKEN_NAME;
					st->blockName->keyword = KEYWORD_NONE;
				}
				corkIndex = qualifyBlockTag (st, name_token);
			}
			break;

		case TOKEN_KEYWORD:
			break;

		case TOKEN_SEMICOLON:
		case TOKEN_COMMA:
			if (insideEnumBody (st))
				;
			else if (isType (prev, TOKEN_NAME))
			{
				if (isContextualKeyword (prev2))
					corkIndex = makeTag (prev, st, true, TAG_EXTERN_VAR);
				else
					corkIndex = qualifyVariableTag (st, prev);
			}
			else if (isType (prev, TOKEN_ARGS)  &&  isType (prev2, TOKEN_NAME))
			{
				if (st->isPointer || st->inFunction)
				{
					/* If it looks like a pointer or we are in a function body then
					   it's far more likely to be a variable. */
					corkIndex = qualifyVariableTag (st, prev2);
				}
				else
					corkIndex = qualifyFunctionDeclTag (st, prev2);
			}
			break;

		default: break;
	}

	return corkIndex;
}

/*  Parses the current file and decides whether to write out and tags that
 *  are discovered.
 */
static void createTags (const unsigned int nestLevel,
						statementInfo *const parent)
{
	statementInfo *const st = newStatement (parent);

	DebugStatement ( if (nestLevel > 0) debugParseNest (true, nestLevel); )
	while (true)
	{
		tokenInfo *token;

		nextToken (st);
		token = activeToken (st);
		if (isType (token, TOKEN_BRACE_CLOSE))
		{
			if (nestLevel > 0)
				break;
			else
			{
				verbose ("%s: unexpected closing brace at line %lu\n",
						getInputFileName (), getInputLineNumber ());
				longjmp (Exception, (int) ExceptionBraceFormattingError);
			}
		}
		else if (isType (token, TOKEN_DOUBLE_COLON))
		{
			addContext (st, prevToken (st, 1));
			advanceToken (st);
		}
		else
		{
			int corkIndex = tagCheck (st);
			if (isType (token, TOKEN_BRACE_OPEN))
				nest (st, nestLevel + 1);
			checkStatementEnd (st, corkIndex);
		}
	}
	deleteStatement ();
	DebugStatement ( if (nestLevel > 0) debugParseNest (false, nestLevel - 1); )
}

static rescanReason findCTags (const unsigned int passCount)
{
	exception_t exception;
	rescanReason rescan;
	int kind_for_define = VK_DEFINE;
	int kind_for_header = VK_HEADER;
	int kind_for_param  = VK_MACRO_PARAM;
	int role_for_macro_undef = VR_MACRO_UNDEF;
	int role_for_macro_condition = VR_MACRO_CONDITION;
	int role_for_header_system   = VR_HEADER_SYSTEM;
	int role_for_header_local   = VR_HEADER_LOCAL;

	Assert (passCount < 3);

	AnonymousID = 0;

	cppInit ((bool) (passCount > 1), false, false,
		 true,
		 kind_for_define, role_for_macro_undef, role_for_macro_condition, kind_for_param,
		 kind_for_header, role_for_header_system, role_for_header_local,
		 FIELD_UNKNOWN);

	Signature = vStringNew ();

	exception = (exception_t) setjmp (Exception);
	rescan = RESCAN_NONE;
	if (exception == ExceptionNone)
		createTags (0, NULL);
	else
	{
		deleteAllStatements ();
		if (exception == ExceptionBraceFormattingError  &&  passCount == 1)
		{
			rescan = RESCAN_FAILED;
			verbose ("%s: retrying file with fallback brace matching algorithm\n",
					getInputFileName ());
		}
	}
	vStringDelete (Signature);
	cppTerminate ();
	return rescan;
}

static void buildKeywordHash (const langType language, unsigned int idx)
{
	const size_t count = ARRAY_SIZE (KeywordTable);
	size_t i;
	for (i = 0  ;  i < count  ;  ++i)
	{
		const keywordDesc* const p = &KeywordTable [i];
		addKeyword (p->name, language, (int) p->id);
	}
}

static void initializeVeraParser (const langType language)
{
	Lang_vera = language;
	buildKeywordHash (language, 0);
}

extern parserDefinition* VeraParser (void)
{
	static const char *const extensions [] = { "vr", "vri", "vrh", NULL };
	parserDefinition* def = parserNew ("Vera");
	def->kindTable      = VeraKinds;
	def->kindCount  = ARRAY_SIZE (VeraKinds);
	def->extensions = extensions;
	def->parser2    = findCTags;
	def->initialize = initializeVeraParser;
	// end: field is not tested.

	/* cpreprocessor wants corkQueue. */
	def->useCork    = CORK_QUEUE;

	return def;
}
