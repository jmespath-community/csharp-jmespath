# JMESPath.Net

A fully compliant implementation of [JMESPath](http://jmespath.org/specification.html) for .NET.

#### Build
[![.NET Build and Compliance](https://github.com/jmespath-community/csharp-jmespath/actions/workflows/build.yaml/badge.svg)](https://github.com/jmespath-community/csharp-jmespath/actions/workflows/build.yaml)

#### NuGet
[![NuGet Badge](https://shields.io/nuget/v/JMESPath.Net)](https://www.nuget.org/packages/JMESPath.Net)
 
# Getting started

## Using the parser

`JMESPath.Net` uses [Newtonsoft.Json](http://www.newtonsoft.com/json) to handle [JSON](http://json.org/)
and comes with a simple to use parser:

```c#
using DevLab.JmesPath;

const string input = @"{ \"foo\": \"bar\" }";
const string expression = "foo";

var jmes = new JmesPath();
var result = jmes.Transform(input, expression);

```

The `JmesPath.Transform` method accepts and produces well formed JSON constructs (object, array or string, boolean, number and null values).
In the example above, the `result` is a JSON string token, including the quotes.

```c#
using Newtonsoft.Json.Linq;

System.Diagnostics.Debug.Assert(result == "\"bar\"");

var token = JToken.Parse(result);
var text = token.ToString();

System.Diagnostics.Debug.Assert(text == "bar");

```

## Exploiting the AST

The previous example return the result of the JMESPath evaluation in a single function call.
The JMESPath.Net parser, however, create an abstract syntax tree with a root [`JmesPathExpression`](./blob/master/src/jmespath.net/Expressions/JmesPathExpression.cs) object used for evaluating JMESPath expression against a JSON document.

If you want to retrieve the AST before performing evaluations, use the following code:

```c#
var jp = new JmesPath();
var ast = jp.Parse(expression);

System.Diagnostics.Debug.Assert(ast is JmesPathExpression);

```

Here is the inheritance hierarchy of `JmesPathExpression` objects:


```mermaid
classDiagram
	class JmesPathExpression
	JmesPathExpression: +bool IsExpressionType()
    JmesPathExpression <|-- JmesPathSimpleExpression
    JmesPathExpression <|-- JmesPathCompoundExpression
    JmesPathExpression <|-- JmesPathProjection
    JmesPathExpression <|-- JmesPathFunctionExpression
    JmesPathExpression <|-- JmesPathLetExpression
    JmesPathExpression <|-- JmesPathVariableReference

	JmesPathFunctionExpression: +string Name
	JmesPathFunctionExpression: +JmesPathExpression[] Arguments
```

### Leaf Expressions

```mermaid
classDiagram
    JmesPathExpression <|-- JmesPathCurrentNode
    JmesPathExpression <|-- JmesPathIdentifier
    JmesPathExpression <|-- JmesPathIndex
    JmesPathExpression <|-- JmesPathLiteral
    JmesPathExpression <|-- JmesPathMultiSelectHash
    JmesPathExpression <|-- JmesPathMultiSelectList
    JmesPathExpression <|-- JmesPathRawString

	JmesPathMultiSelectList: +JmesPathExpression[] Expressions
	JmesPathMultiSelectHash: +IDictionary~string, JmesPathExpression~ Dictionary
	JmesPathIdentifier: +string Name
	JmesPathIndex: +int Index
	JmesPathLiteral: +JToken Value
	JmesPathRawString: + string Value
```

### Simple Expressions

A simple expression encapsulates a single instance of another expression named `Expression`.

```mermaid
classDiagram
	class JmesPathSimpleExpression
	JmesPathSimpleExpression: +JmesPathExpression Expression

	JmesPathSimpleExpression <|-- JmesPathNotExpression
	JmesPathSimpleExpression <|-- JmesPathParenExpression
```
### Compound Expressions

Compound expressions are a combination of two expressions, named `Left` and `Right`.


```mermaid
classDiagram
	class JmesPathCompoundExpression
	JmesPathCompoundExpression: +JmesPathExpression Left
	JmesPathCompoundExpression: +JmesPathExpression Right

	JmesPathCompoundExpression <|-- JmesPathAndExpression
	JmesPathCompoundExpression <|-- JmesPathComparison
	JmesPathCompoundExpression <|-- JmesPathIndexExpression
	JmesPathCompoundExpression <|-- JmesPathOrExpression
	JmesPathCompoundExpression <|-- JmesPathPipeExpression
	JmesPathCompoundExpression <|-- JmesPathSubExpression
```

```mermaid
classDiagram
	JmesPathProjection <|-- JmesPathFilterProjection
	JmesPathProjection <|-- JmesPathFlattenProjection
	JmesPathProjection <|-- JmesPathHashWildcardProjection
	JmesPathProjection <|-- JmesPathListWildcardProjection
	JmesPathProjection <|-- JmesPathSliceProjection

	JmesPathFilterProjection: +JmesPathExpression Expression
	JmesPathSliceProjection: +int? Start
	JmesPathSliceProjection: +int? Stop
	JmesPathSliceProjection: +int? Step
```

```mermaid
classDiagram
	JmesPathComparison <|-- JmesPathEqualOperator
	JmesPathComparison <|-- JmesPathOrderingComparison
	JmesPathComparison <|-- JmesPathNotEqualOperator
```

```mermaid
classDiagram
	JmesPathOrderingComparison <|-- JmesPathGreaterThanOperator
	JmesPathOrderingComparison <|-- JmesPathGreaterThanOrEqualOperator
	JmesPathOrderingComparison <|-- JmesPathLessThanOperator
	JmesPathOrderingComparison <|-- JmesPathLessThanOrEqualOperator
```