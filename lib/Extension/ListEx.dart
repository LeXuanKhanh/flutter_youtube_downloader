extension ListEx<T> on List<T> {
  T? valueAt({required int index}) {
    if (index < this.length) {
      return this[index];
    }
    return null;
  }

  T? tryFirst() {
    if (this.isEmpty) {
      return null;
    }

    return this.first;
  }

  T? tryLast() {
    if (this.isEmpty) {
      return null;
    }

    return this.last;
  }

}