[![ru](https://img.shields.io/badge/lang-ru-red.svg)](https://github.com/mzujev/lattelua/blob/main/README.md)
---

# Lattelua Language Reference

Lattelua is a dynamic scripting language compiled to Lua. It is based on the semantics (parser/lexer) of [MoonScript](https://moonscript.org/), but uses a JavaScript-like syntax, allowing for free code formatting and easy minification.

Main differences from [MoonScript](https://moonscript.org/):
* **Block structure**: Use `{` and `}` instead of indentation.
* **Free formatting**: Ignore line breaks and spaces.
* **Delimiters**: Use `;` to separate instructions (the preprocessor replaces them with newlines).
* **Method Syntax**: The `::` operator for calling instance methods.
* **Switch**: Keyword `case` instead of `when`.
* **Error handling**: Built-in `try/catch/finally` construct.
* **Standalone interpreter**: `llua` with compilation listing capability.

## Table of Contents

1. [Basic Syntax](#Basic-Syntax)
   - [Code blocks and delimiters](#Code-blocks-and-delimiters)
   - [Comments](#Comments)
2. [Variables and assignment](#Variables-and-assignment)
   - [Updating values](#Updating-values)
   - [Global variables](#Global-variables)
3. [Data Types and Tables](#Data-Types-and-Tables)
   - [Literals](#Literals)
   - [String interpolation](#String-interpolation)
   - [Tables](#Tables)
   - [Destructuring](#Destructuring)
   - [Collection Generators](#Collection-Generators)
     * [List Generators](#List-Generators)
     * [Table Generators](#Table-Generators)
4. [Control structures](#Control-structures)
   - [If/Else/Unless](#If-Else-Unless)
   - [Operator Switch](#Operator-Switch)
5. [Cycles](#Cycles)
6. [Linear decorators](#Linear-decorators)
7. [Functions](#Functions)
8. [Object-oriented programming](#Object-oriented-programming)
   - [Classes](#Classes)
   - [Inheritance](#Inheritance)
9. [With operator](#With-operator)
10. [Do operator](#Do-operator)
11. [Error Handling (Try-Catch)](#Error-Handling-Try-Catch)
12. [Standalone interpreter](#Standalone-interpreter)

### Basic syntax

### Code blocks and delimiters
In **Lattelua**, indentation is irrelevant. Grouping of statements is done using `{` and `}`. The `;` character is used as a statement separator, allowing you to write code on a single line:

```moonscript
-- Normal entry
if true {
	print("Hello")
}

-- Single-line entry
if true { print("Hello") }
```

### Comments

Comments are ignored by the compiler. The `;` character within comments and lines is not processed by the preprocessor:

```moonscript
-- This is a one-line comment.

--[[
		This is a multi-line comment.
		It works exactly the same as in Lua.
		MoonScript does not support this type of comment!
--]]
```

### Variables and assignment

By default, all variables are local (`local`):

```moonscript
a = 1              -- local a = 1
str = "hello"      -- local str = "hello"
x, y = 10, 20      -- local x, y = 10, 20
```

### Updating values

The following operators are available for quickly updating values: `+=`, `-=`, `*=`, `/=`, `%=`, `..=`:

```moonscript
count = 0
count += 1         -- count = count + 1
name = "Lattelua"
name ..= "Lang"    -- Concatenation
```

### Global variables

To create a global variable or export one from a module, use the `export` keyword:

```moonscript
export VERSION = "1.0"
```

This is especially useful when declaring something that will be visible externally in a module:

```moonscript
-- some module.llua
export some_print

add = (x, y) -> { x + y }

some_print = (x, y) -> {print "Addition is: ", add x, y}



-- some script.llua
require "some_module"

some_module.some_print 5, 10         -- 15
print some_module.add 5, 10          -- errors, `add` not visible
```

Exporting will have no effect if there is already a local variable with the same name in scope.

In the context of variables, it is often necessary to transfer some values from a table/module to the current scope as local variables by their name.

The `import` keyword is used for this:

```moonscript
import insert from table             -- local insert = table.insert
```

You can specify multiple names, each separated by commas:

```moonscript
import C, Ct, Cmt from lpeg          -- local C, Ct, Cmt = lpeg.C, lpeg.Ct, lpeg.Cmt
```

Sometimes you need to pass a table as the `self` argument. For shorthand, you can prefix the function name with `::` to associate the function with that table:

```moonscript
t = {
	val: 100
	add: (value) => {
		self.val + value
	}
}

import ::add from t

print add 22                         -- equivalent to add(t, 22) or t::add(22)
```

### Data Types and Tables

### Literals

```moonscript
num = 123  
float = 1.5  
str_double = "Text"  
str_single = 'Text'
str_multi = [[
	multi-line
	text
]]
bool = true  
nothing = nil
```

### String interpolation

It is allowed to mix expressions with string literals using the `#{}` syntax:

```moonscript
print "This is #{math.random() * 100}% work, I'm sure"              -- print("This is " .. tostring(math.random() * 100) .. "% work, I'm sure")
```

String interpolation is only available in strings enclosed in double quotes.

### Tables

As in Lua, tables are enclosed in curly braces:

```moonscript
array = { 1, 2, 3, 4 }
```

Unlike Lua, assigning a value to a key in a table is done using `:` (instead of `=`):

```moonscript
config = {  
	port: 8080,  
	host: "localhost",
	list: { 1, 2, 3 },  
	["key with spaces"]: "some value"
}
```

A newline can be used to separate values instead of a comma (or both):

```moonscript
config = {  
	port: 8080  
	host: "localhost"
	list: { 1, 2, 3 }  
	["key with spaces"]: "some value"
}
```

Table keys can be unescaped language keywords:

```moonscript
t = {
	do: "do"
	end: "end"
}
```

If you are creating a table from variables and want the keys to match the variable names, you can use the prefix operator `:`:

```moonscript
gender = "male"
age = 25

person = {
	:gender                         -- gender: gender
	:age                            -- age: age
	key: "value"                    -- key: "value"
}

print :gender, :age               -- {gender: gender, age: age}
```

If you want a key to be the result of an expression, you can wrap it in `[]`, as in Lua. It's also possible to use a string literal directly as a key, omitting the square brackets. This is useful if the key contains special characters:

```moonscript
t = {
	[1 + 2]: "three",
	["some value"]: true,
	"another some value": false
}
```

### Destructuring

Destructuring is a way to quickly extract values from a table by their name or position in array-based tables.

```moonscript
vec = { x: 10, y: 20, z: 30 }

{ :x, :y } = vec

print(x, y)                        -- 10 20

arr = {1, 2, 3}

{f,_,t} = arr

print f, t                         -- 1 3
```

This also works with nested data structures:

```moonscript
obj = {
	array: {1, 2, 3, 4}
	properties: {
		align: "center"
		vec: { x: 10, y: 20, z: 30 }
	}
}

{
	array: { first, second }
	properties: {
		:align
		vec: { :x, :y }
	}
} = obj

-- first, second, align, x, y = obj.array[1], obj.array[2], obj.properties.align, obj.properties.vec.x, obj.properties.vec.y

```

Typically, values are retrieved from a table and assigned to local variables that have the same name as the key. To avoid repetition, the prefix operator `:` can be used:

```moonscript
{:concat, :insert} = table             -- local concat, insert = table.concat, table.insert
```

This is essentially the same as `import`, but we can rename the fields we want to extract:

```moonscript
{:mix, :max, random: rand } = math     -- local mix, max, rand = math.mix, math.max, math.random
```

Destructuring can also occur in places where assignment is implicitly performed:

```moonscript
array = {
	{1, 2, 3, 4}
	{5, 6, 7, 8}
}

for {first, second} in *array {
	print first, second                  -- 1 2 & 5 6
}

```

### Collection Generators

Generators provide a convenient syntax for creating a new table by iterating over some existing object and applying an expression to its values.
There are two types of generators: list generator and table generator.
They both create Lua tables.
List comprehensions accumulate values into an array-like table, while table comprehensions allow you to set both the key and the value on each iteration.

### List generators

The following example creates a copy of the element table, with doubled values:

```moonscript
array = { 1, 2, 3, 4 }
doubled = [item * 2 for i, item in ipairs array]           -- doubled = { 2, 4, 6, 8 }
```

The elements included in the new table can be limited using the `when` expression:

```moonscript
iter = ipairs array
slice = [item for i, item in iter when i > 1 and i < 3]    -- slice = { 2 }
```

The `for` and `when` operators can be chained together as many times as desired. The only requirement is that the expression contain at least one `for` operator.

Using multiple for statements is similar to using nested loops:

```moonscript
x = {4, 5, 6, 7}
y = {9, 2, 3}

points = [{x,y} for x in ipairs x for y in ipairs y]
```

### Table generators

The syntax for the table generator is very similar, differing only in the use of `{}` and the production of two values on each iteration:

```moonscript
t ={
	gender: "male",
	Age: 25
}
copy = {k,v for k,v in pairs t}
```

Table comprehensions, like list comprehensions, also support multiple `for` and `when` statements:

```moonscript
copy = {k,v for k,v in pairs t when k != "gender"}
```

### Control structures

### If Else Unless

```moonscript
if x > 10 {  
	print("Big")  
} elseif x == 10 {  
	print("Equal")  
} else {  
	print("Small")  
}

-- Unless (if NOT)  
unless ready {  
	init()  
}

-- Ternary Operator / One-Line If  
val = if check { true; } else { false; }
```

Conditional expressions can also be used in return statements and assignments:

```moonscript
test = (c)->{
	if c {
		true
	} else {
		false
	}
}

out = if test true {
	"is true"
} else {
	"is false"
}

print out               -- "is true"
```

### Switch Operator

Uses the `case` keyword for branches and `else` for the default value:

```moonscript
value = 2

switch value {  
	case 1
		print("One")
	case 2
		print("Two")
	case 1,2,3
		print "One..Three"
	else
		print("Other")
}
```

`switch` can also be used as an expression, thereby assigning the result of `switch` to a variable:

```moonscript
out = switch value {  
	case 1
		"One"
	case 2
		"Two"
	case 1,2,3
		"One...Three"
	else
		"Other"
}

print out               -- "Two"
```

### Cycles

### For (Numeric)

```moonscript
-- Without a step
for i = 1, 10 {  
	print(i)              -- 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
}

-- With a step  
for i = 0, 10, 2 {  
	print(i)              -- 0, 2, 4, 6, 8, 10
}
```

### For In (Iterator)

```moonscript
t = { a: 1, b: 2 }  
for k, v in pairs(t) {  
	print(k, v)
}
```

The `for` loop can also be used as an expression. The last statement of the loop body is converted to an expression and added to the accumulative array table.

Doubling every even number:

```moonscript
doubled = for i=1.20 {
	if i % 2 == 0 {
		i * 2
	} else {
		i
	}
}

print i for _,i in ipairs doubled                -- 4, 8, 12, 16, 20, 24, 28, 32, 36, 40
```

It is also possible to filter values by combining `for` loop expressions with the [continue](#Continue) operator.

`for` loops at the end of a function body do not accumulate in the table for the return value (the function will return `nil` instead).
An explicit return statement can be used, or the loop can be converted into a list comprehension.

```moonscript
funca = -> {for i=1,10 {i}}
funcb = -> {return [i for i=1,10] }

print funca()      -- prints nil
print funcb()      -- prints table object
```

This is done to avoid unnecessary table creation for functions that do not need to return loop results.

### While

The `while` loop also comes in two variants:

```moonscript
i = 10
while i > 0 {
	print i
	i -= 3
}

while running == true {some_func()}
```

As with the for loop, you can also use an expression in the while loop. However, for the function to return the accumulated value of the while loop, the statement must be explicitly returned.

### Cycle control

### Break

The break statement terminates a loop (`while` or `for`) in which it occurs. Execution of the break statement transfers control to the first statement immediately following the loop statement.

```moonscript
i = 0
while i < 10 {
	break if i > 5
	print i
	i += 1
}
```

### Continue

The `continue` operator can be used to skip the current iteration in a loop.

```moonscript
i = 0
while i < 10 {
	continue if i % 2 == 0
	print i
	i += 1
}
```

Also `continue` can be used with loop expressions to prevent that iteration from accumulating into a result.

This example filters the array to only contain even numbers:

```moonscript
array = {1,2,3,4,5,6}
odds = for x in ipairs array {
	continue if x % 2 == 1
	x
}
```

### Functions

All functions are created using a functional expression. A simple function is denoted by an arrow: `->`

```moonscript
some_func = ->
some_func()             -- call that empty function
```

The body of a function can be either a single statement or a series of statements placed directly within the curly brace block, immediately after the arrow:

```moonscript
funca = -> {print "hello world"}

funcb = -> {
	message = "world"
	print "hello #{message}"
}
```

If a function has no arguments, it can be called using the `!` operator, instead of empty parentheses. The `!` call is the preferred way to call functions without arguments.

```moonscript
funca!
funcb()
```

Functions with arguments can be created by preceding the arrow with a list of argument names in parentheses:

```moonscript
sum = (a, b) -> {  
	return a + b  
}
```

Default values can be specified for function arguments. An argument is considered empty if its value is zero. Any zero arguments that have a default value will be replaced before the function body is run.

```moonscript
greet = (name = "World") -> {  
	print("Hello " .. name)  
}
```

Default argument values are evaluated within the function body in the order the arguments are declared. This is why default values have access to previously declared arguments.

```moonscript
(x=100, y=x+1000) -> {
	print x + y
}
```

Functions can be called by listing arguments after the name of the expression that evaluates to the function. When chaining function calls, the arguments are applied to the closest function on the left.

```moonscript
sum 10, 20              -- sum(10, 20)
print sum 10, 20        -- print(sum(10, 20))

abc "a", "b", "c"       -- a(b(c("a", "b", "c")))
```

To avoid ambiguity when calling functions, arguments can also be enclosed in parentheses. This is necessary in the example below to ensure that the correct arguments are sent to the correct functions.

```moonscript
print "x:", sum(10, 20), "y:", sum(30, 40) -- print("x:", sum(10, 20), "y:", sum(30, 40))
```

There should be no space between the opening parenthesis and the function (**sum**).

As in Lua, functions can return multiple values. The final statement must be a comma-separated list of values:

```moonscript
some_func = (x, y) -> {x + y, x - y}
a, b = some_func 10, 20
```

### Self-context

To create functions, there is a special syntax `=>`, which automatically includes the `self` argument.

```moonscript
obj = {  
	val: 10  
	update: (num) => {  
		self.val = num      -- self is passed automatically  
	}  
}

obj::update(13)

print obj.val               -- val = 13
```

### Linear decorators

For convenience operators loop `for` and `if`, can be applied to individual statements at the end of a line:

```moonscript
print "hello world" if 1 == 1
```

And with basic cycles:

```moonscript
print "value: #{v}" for _, v in ipairs {1,2,3,4,5,6}
```

### Object-oriented programming

### **Classes**

A class is declared using the `class` statement, followed by a table declaration that lists all the methods and properties.

```moonscript
class Animal {
	new: (name) => {
		self.name = name
	}
	speak: => {
		print(self.name)
	}
}
```

A class declaration can also be used as an expression that can be assigned to a variable or returned explicitly.

The `new` method, if defined, becomes a constructor.

Creating an instance of a class is done by calling the class name as a function.

```moonscript
dog = Animal "woof woof"
```

All class properties are shared across all instances. This is fine for methods, but for other object types, undesirable results can occur:

```moonscript
class Animal {
	speech: {}
	new: (speech) => {
		table.insert self.speech, speech
	}
	speak: (who) => {
		print "#{who} say: #{speech}" for _, speech in ipairs self.speech
	}
}

dog = Animal "woof"
cat = Animal "meow"

dog::speak("dog")       -- will print both `woof` and `meow`
cat::speak("dog")       -- will print both `woof` and `meow`
```

The `speech` property is shared across all instances, so changes made to it in one instance will be reflected in the other.
The correct way to avoid this behavior is to create the mutable state of the object in the constructor:

```moonscript
class Animal {
	new: (speech) => {
		self.speech = {}                   -- private property for instance
		table.insert self.speech, speech
	}
	speak: (who) => {
		print "#{who} say: #{speech}" for _, speech in ipairs self.speech
	}
}
```

### Inheritance

The `extends` keyword can be used in a class declaration to inherit the properties and methods of another class.

```moonscript
class Dog extends Animal {
	new: (speech) => {
		super(speech)
	}

	speak: (who)=> {
		print("#{who} say: WOOF")
	}
}
```

If a subclass does not define a constructor, the parent class constructor is called when a new instance is created.
If a constructor is defined, then the `super` method can be used to call the parent class constructor.

`super` is a special keyword that can be used in two ways: as an object or as a function. `super` has functionality only within a class.
When called as a function, `super` will call the function of the same name in the parent class. The current `self` object will automatically be passed as the first argument.
When using `super` as a normal value, it is a reference to an object of the parent class.
`super` can be accessed like any object to retrieve values in the parent class.

When a child class inherits, it sends a message to the parent class by calling the parent class's `__inherited` method, if it exists. The method takes two arguments: the inherited class and the child class:

```moonscript
class Animal {
	__inherited: (child) => {
		print "#{self.__name} was inherited by #{child.__name}"
	}
}

class Dog extends Animal{}
```

### With operator

The `with` block allows you to shorten your code when accessing a single object multiple times. Within the block, properties beginning with `.` or methods beginning with `::` are assigned to the target object.

```moonscript
user = { name: "John", age: 30 }
user.show = => { print self.name }

with user {
	.name ..= "Doe"            -- user.name = "John Doe"
	::show()                   -- user:show()
	print(.age)                -- print(user.age)
}
```

The `with` operator can also be used as an expression, returning the value it provides access to:

```moonscript
name = with user {
	.name = 'Jane Smith'
}

name::show()                 -- Jane Smith
```

The expression in the `with` statement can also be an assignment if you want to give the expression a name:

```moonscript
name = with n = setmetatable{name: user.name},{__index: user} {
	.name = 'John Doe'
}

name::show()                 -- John Doe
user::show()                 -- Jane Smith
```

### Do operator

Using the `do` operator works the same as in Lua.

```moonscript
do {
	msg = "world"
	print "hello #{msg}"
}
```

The `do` statement can also be used as an expression. The result of a `do` expression is the last expression in the block.

```moonscript
print do {
	msg = "world"
	"hello #{msg}"
}
```

The `do` operator can be used to extend syntactic constructs:

```moonscript

do {
  print "#{k} => #{v}" if k != "lattelua" else do {
    print "\t#{kk} => #{vv}" for kk,vv in pairs lattelua
  }
} for k,v in pairs _G

--        compiles to
-- for k, v in pairs(_G) do
--   do
--     if k ~= "lattelua" then
--       print(tostring(k) .. " => " .. tostring(v))
--     else
--       do
--         for kk, vv in pairs(lattelua) do
--           print("\t" .. tostring(kk) .. " => " .. tostring(vv))
--         end
--       end
--     end
--   end
-- end

```

### Error Handling (Try-Catch)

The `try` block is used to handle exceptions. This allows you to test a block of code for errors and handle them gracefully, preventing unexpected program failure.

```moonscript
try {
	-- The code that causes the error
	error("Boom!")
} catch {
	-- Error handling (self contains the error text)
	print("Error caught: " .. self)
} finally {
	-- Always executed if present
	print("Cleanup")
}
```
 
The `try` operator can also be used as an expression. The result of a `try` expression is the last expression in the `try/catch` blocks, respectively.

### Standalone interpreter

The standalone interpreter `llua` is installed along with `LatteLua`. This interpreter is designed for both directly running `LatteLua` code and compiling code to `Lua`.

```sh
llua [options] [script [args]]
```
Launch options:
* `-e code` - executes the string `code`
* `-l name` - loads the `name` library
* `-i` - interactive mode after `script` execution
* `-c` - compile and print the resulting `lua` code
* `--` - stop processing options
* `-` - execute `stdin` and stop processing options

