# FX

A Swift port of Scala Futures.

A Future is a data structure used to retrieve the result of some concurrent operation. This result can be accessed synchronously or asynchronously.

The library also contains some basic primitives like materialized exceptions (``Try``) and atomic objects (``AtomicReference``) needed for its implementation.

## Documentation

- [Scala Futures documentation](http://docs.scala-lang.org/overviews/core/futures.html)
- [Wikipedia](https://en.wikipedia.org/wiki/Futures_and_promises)

## Example

```swift

      let f = Future { 5 }
      let g = f.filter { $0 % 2 == 1 }
      let h = f.filter { $0 % 2 == 0 }
    
      let gResult = Try { try Await.result(g, atMost: Duration.Zero) }
      let hResult = Try { try Await.result(h, atMost: Duration.Zero) }
```
