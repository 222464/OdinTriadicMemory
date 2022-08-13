package triadic

import "core:math"
import "core:math/rand"

Diadic_Memory :: struct {
    nx, ny, p: int,

    mem: []u8,

    // Temporaries
    sums: []int,
}

diadic_memory_new :: proc(nx: int, ny: int, p: int) -> Diadic_Memory {
    dm := Diadic_Memory{nx, ny, p, make([]u8, ny * nx * (nx - 1) / 2), make([]int, ny)}

    return dm
}

diadic_memory_free :: proc(dm: Diadic_Memory) {
    delete(dm.mem)
    delete(dm.sums)
}

diadic_memory_add :: proc(dm: Diadic_Memory, x: SDR, y: SDR) {
    for i in 1..<x.p {
        for j in 0..<i {
            start := dm.ny * (x.indices[j] + x.indices[i] * (x.indices[i] - 1) / 2)

            for k in 0..<y.p {
                index := y.indices[k] + start

                dm.mem[index] = min(255, dm.mem[index] + 1)
            }
        }
    }
}

diadic_memory_remove :: proc(dm: Diadic_Memory, x: SDR, y: SDR) {
    for i in 1..<x.p {
        for j in 0..<i {
            start := dm.ny * (x.indices[j] + x.indices[i] * (x.indices[i] - 1) / 2)

            for k in 0..<y.p {
                index := y.indices[k] + start

                dm.mem[index] = max(0, dm.mem[index] - 1)
            }
        }
    }
}

diadic_memory_read_y :: proc(dm: Diadic_Memory, x: SDR, y: ^SDR) {
    for i in 0..<dm.ny do dm.sums[i] = 0

    for i in 1..<x.p {
        for j in 0..<i {
            start := dm.ny * (x.indices[j] + x.indices[i] * (x.indices[i] - 1) / 2)

            for k in 0..<dm.ny {
                index := k + start

                dm.sums[k] += int(dm.mem[index])
            }
        }
    }

    sdr_inhibit(y, dm.sums, dm.p)
}
