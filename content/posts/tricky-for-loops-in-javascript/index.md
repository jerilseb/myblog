+++
title = "For loops are tricky in Javascript"
description = "Tricky for loops in Javascript"
tags = [
    "javascript"
]
date = "2019-03-22"
categories = [
    "Javascript",
]
draft = false
+++

If you have been to a frontend interview, you've probably been asked some variation of the below question.

**What will be the output of the following code snippet?**

```javascript
for (var i = 0; i < 3; i++) {
    setTimeout(() => {
        console.log(i);
    }, 0);
}
```

You manage to avoid all the trickery, while showing off your knowledge of the event loop, and arrive at the correct answer, which is _3 getting printed 3 times_. You'll most likely get a follow-up question, 

**How can we fix this?**

The intent of the question is to print numbers from 0 to 2. Again, you wield your knowledge of closures and use an IIFE to wrap the setTimeout callback in a closure, which creates a different `i` for each iteration of the loop.

```javascript
for (var i = 0; i < 3; i++) {
    setTimeout(((i) => {
        console.log(i);
    })(i), 0);
}
```

Or instead of an IIFE, maybe you solved it by replacing the the arrow function with a regular function and using the `bind` method to bind the `this` to the `i` variable.

```javascript
for (var i = 0; i < 3; i++) {
    setTimeout((function() {
        console.log(this);
    }).bind(i), 0);
}
```

But here in 2018, there is a simpler alternative. All you have to do is replace the `var` with the new `let` keyword and it works.

```javascript
for (let i = 0; i < 3; i++) {
    setTimeout(() => {
        console.log(i);
    }, 0);
}
```

But wait, how is this even working? Is every iteration of the loop getting a new `i`? If not, `i` would be mutated by every iteration of the loop and the result would be the same value getting printed 3 times. But if every iteration is getting a new `i`, how does it remember the value of `i` from the previous iteration? Is the value somehow getting copied over at the end of each iteration?

The answer is **YES**. in fact, the ECMAScript 2015 specification has a [section](http://www.ecma-international.org/ecma-262/6.0/#sec-for-statement-runtime-semantics-labelledevaluation) dedicated to handling `let` and `const` declarations in a `for` loop (_talk about keeping things simple_). You can contrast it with the [same section](https://www.ecma-international.org/ecma-262/5.1/#sec-12.6.3) ECMAScript 5.1 specification of `for` loops and see how much complexity has been added by use of `let` and `const`.

If you don't mind taking a look at the [spec](http://www.ecma-international.org/ecma-262/6.0/#sec-for-statement-runtime-semantics-labelledevaluation), you can see that during the evaluation of the for loop body, the method `CreatePerIterationEnvironment()` is creating a new lexical environment using `perIterationBindings` for each iteration. 

```
The abstract operation ForBodyEvaluation with arguments ..., perIterationBindings, 
and labelSet is performed as follows:

Let status be CreatePerIterationEnvironment(perIterationBindings).
Repeat
    If test is not [empty], then
        i. Let testRef be the result of evaluating test.
        ii. Let testValue be GetValue(testRef).
        ...
        iv. If ToBoolean(testValue) is false, return NormalCompletion(V).
    ...
    Let status be CreatePerIterationEnvironment(perIterationBindings).
    ...
```


Also, one more thing becomes immediately apparent. The statement `i++` is being executed at the beginning of each iteration (_except the first one ofcourse_). Otherwise, the `i` in the first iteration's environment would have been incremented and the first value to get printed would have been **1**.

Armed with this knowledge, let's try something a little weird. What would be the output of the following code?

```javascript
for (let i = 0, j = setTimeout(() => console.log(i)); i < 3;) {
    i++;
}
```

As per our current understanding, since `i++` is inside the body, it will be executed in the first iteration and and the output would be **1**. Try executing the snippet. 

Uh, oh! The output is **0**. What's happening here? 

Turns out, even before the first iteration, a lexical environment is created for the loop __initiliaztion section__ and copied over to the loop __body evaluation__. If we look at the [specification](http://www.ecma-international.org/ecma-262/6.0/#sec-for-statement-runtime-semantics-labelledevaluation), we can see that the method `NewDeclarativeEnvironment()` at _step 2_ is creating a lexical environment and it is being passed down to the body evaluation at _step 10_.

```
IterationStatement : for ( LexicalDeclaration Expressionopt ; Expressionopt ) Statement

1. Let oldEnv be the running execution context’s LexicalEnvironment.
2. Let loopEnv be NewDeclarativeEnvironment(oldEnv).
...
4. Let boundNames be the BoundNames of LexicalDeclaration.
...
9. If isConst is false, let perIterationLets be boundNames
10. Let bodyResult be ForBodyEvaluation(..., perIterationLets, ...).
```

You must be thinking, that's a lot of hoops to jump through just to evaluate a loop. But this is necessary because, the semantics of block scoping should seamlessly work with asynchronous calls anywhere in the loop. The good news is that as a programmer, you mostly wouldn't have to worry about any of these. Even with all these complicated semantics, for most practical purposes, it behaves like a `for` loop from any other language.

That's all for this post. Thank you for reading.