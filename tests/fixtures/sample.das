options gen2

require daslib/strings_boost

struct Point {
    x, y : float = 0.0
}

[export]
def main(args : array<string>) : int {
    var total = 0
    for (arg in args) {
        total += length(arg)
    }
    let origin = Point(x = 1.0, y = 2.0)
    print("total {total} at {origin.x}\n")
    return total
}
