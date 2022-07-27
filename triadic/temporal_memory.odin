package triadic

import "core:math"
import "core:math/rand"

Temporal_Memory :: struct {
    m1, m2: Triadic_Memory,

    x, h, y, c, pred: SDR,

    randomize_buffer: []int,
}

temporal_memory_new :: proc(n: int, p: int) -> ^Temporal_Memory {
    ttm := new(Temporal_Memory)

    using ttm

    m1 = triadic_memory_new(n, p)
    m2 = triadic_memory_new(n, p)
    x = sdr_new(n, p)
    h = sdr_new(n, p)
    y = sdr_new(n, p)
    c = sdr_new(n, p)
    pred = sdr_new(n, p)
    randomize_buffer = make([]int, n)
    randomize_buffer_init(ttm.randomize_buffer)

    return ttm
}

temporal_memory_free :: proc(ttm: ^Temporal_Memory) {
    using ttm

    triadic_memory_free(m1)
    triadic_memory_free(m2)
    sdr_free(x)
    sdr_free(h)
    sdr_free(y)
    sdr_free(c)
    sdr_free(pred)
    delete(randomize_buffer)

    free(ttm)
}

temporal_memory_flush :: proc(ttm: ^Temporal_Memory) {
    using ttm

    // Flush
    c.p = 0
}

temporal_memory_step :: proc(ttm: ^Temporal_Memory, input: SDR, rng: ^rand.Rand, learn_enabled: bool = true) -> SDR {
    using ttm

    if learn_enabled && !sdr_equal(pred, input) do triadic_memory_add(m2, input, h, c)

    sdr_copy(&c, h)

    triadic_memory_read_y(m1, input, &h, c) // Recall h

    if learn_enabled {
        triadic_memory_read_x(m1, &x, h, c) // Recall input

        if sdr_overlap(x, input) < m1.p {
            h.p = m1.p

            sdr_randomize(h, randomize_buffer, rng)

            triadic_memory_add(m1, input, h, c)
        }
    }

    triadic_memory_read_x(m2, &pred, h, c)

    return pred
}
