extension ListEx<T> on List<T> {
  T? valueAt({required int index}) {
    if (index < this.length) {
      return this[index];
    }
    return null;
  }

  T? get tryFirst {
    if (this.isEmpty) {
      return null;
    }

    return this.first;
  }

  T? get tryLast {
    if (this.isEmpty) {
      return null;
    }

    return this.last;
  }

}