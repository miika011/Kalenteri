import 'dart:collection';
import 'dart:math';

extension SeparatedIteratorExtension<T> on Iterable<T> {
  Iterator<T> separatedIterator(T separator) {
    return SeparatedIterator(iterator, separator: separator);
  }
}

extension SeparatedListExtension<T> on List<T> {
  SeparatedList<T> separatedBy(T separator) =>
      SeparatedList(this, separator: separator);
}

//Iterator that adds separators between elements like:
// i[0] => *SEPARATOR* => i[1] => *SEPARATOR* => i[2]
class SeparatedIterator<T> implements Iterator<T> {
  final Iterator<T> _hookedIterator;
  final T separator;
  bool _isAtSeparator = false;
  bool _wasEmpty = false;

  SeparatedIterator(this._hookedIterator, {required this.separator}) {
    //We are going to move the iterator 1 step further.
    //So that the first actual moveNext doesn't return the separator.
    //We need to handle the special case when the list is empty
    //since otherwise we'd be calling the hooked iterator's moveNext()
    //after the iterator has already reached end.
    _wasEmpty = !moveNext();
  }

  @override
  T get current {
    return _isAtSeparator ? separator : _hookedIterator.current;
  }

  @override
  bool moveNext() {
    if (_wasEmpty) {
      return false;
    }
    bool wasAtSeparator = _isAtSeparator;
    _isAtSeparator = !_isAtSeparator;
    return wasAtSeparator || _hookedIterator.moveNext();
  }
}

class SeparatedIterable<T> extends IterableMixin<T> {
  final T separator;
  final Iterable<T> _hookedIterable;

  SeparatedIterable(this._hookedIterable, {required this.separator});
  @override
  Iterator<T> get iterator =>
      SeparatedIterator<T>(_hookedIterable.iterator, separator: separator);
}

class SeparatedList<T> extends ListMixin<T> {
  @override
  late int length;

  final List<T> _hookedList;
  final T separator;

  SeparatedList(this._hookedList, {required this.separator}) {
    // items|  items_with_separators|   list (* is separator)
    // 0    : 0                     :
    // 1    : 1                     : A
    // 2    : 3                     : A * B
    // 3    : 5                     : A * B * C
    // 4    : 7                     : A * B * C * D
    length = max(0, _hookedList.length * 2 - 1);
  }

  @override
  T operator [](int index) {
    // let hooked_list = [A,B,C] (* is separator)
    //  index|    item
    //  0    :    A (0 on hooked_list)
    //  1    :    *
    //  2    :    B (1 on hooked_list)
    //  3    :    *
    //  4    :    C (2 on hooked_list)
    if (index.isOdd) {
      return separator;
    } else {
      return _hookedList[index ~/ 2];
    }
  }

//Don't allow []= assignment.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
/*
  @override
  void operator []=(int index, T value) {
    // TODO: implement []=
  }
*/
}
