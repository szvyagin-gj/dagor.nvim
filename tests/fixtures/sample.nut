const MAX_STEPS = 3

class Counter {
  count = 0

  function bump() {
    this.count++
    return this.count
  }
}

function run(n) {
  let counter = Counter()
  for (local i = 0; i < n && i < MAX_STEPS; i++)
    counter.bump()
  return counter.count
}
