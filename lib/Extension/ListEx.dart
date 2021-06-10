extension ListEx<T> on List<T> {
  T? valueAt({required int index}) {
    if (index < this.length) {
      return this[index];
    }
    return null;
  }
}