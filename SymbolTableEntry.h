#ifndef SYMBOL_TABLE_ENTRY_H
#define SYMBOL_TABLE_ENTRY_H

#include <string>
using namespace std;

#define UNDEFINED  			-1   // Type codes
#define INT				1
#define STR				2
#define INT_OR_STR			3
#define BOOL				4
#define INT_OR_BOOL			5
#define STR_OR_BOOL			6
#define INT_OR_STR_OR_BOOL		7

   
#define NOT_APPLICABLE 	-1

typedef struct 
{ 
  int type;       // one of the above type codes
  char* value;
} TYPE_INFO;

class SYMBOL_TABLE_ENTRY 
{
private:
  // Member variables
  string name;
  TYPE_INFO typeInfo;

public:
  // Constructors
  SYMBOL_TABLE_ENTRY( ) 
  { 
    name = ""; 
    typeInfo.type = UNDEFINED; 
  }

  SYMBOL_TABLE_ENTRY(const string theName, 
                     const TYPE_INFO theType) 
  {
    name = theName;
    typeInfo.type = theType.type;
    typeInfo.value = theType.value;
  }

  // Accessors
  string getName() const { return name; }
  TYPE_INFO getTypeInfo() const { return typeInfo; }
};

#endif  // SYMBOL_TABLE_ENTRY_H
