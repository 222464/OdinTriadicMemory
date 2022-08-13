package triadic

import "core:math"
import "core:math/rand"

Image_Encoder :: struct {
    m: int,

    h: SDR,

    weights: []u8,

    // Temporaries
    sums: []int,

    // Hyperparameters
    lr: f32,
}

image_encoder_new :: proc(m: int, n: int, p: int, rng: ^rand.Rand) -> ^Image_Encoder {
    ie := new(Image_Encoder)

    ie.m = m
    
    using ie

    h = sdr_new(n, p)

    weights = make([]u8, n * m)

    for i in 0..<n do weights[i] = 0xff - u8(rand.uint32(rng) % u32(3))

    sums = make([]int, n)

    // Hyperparameters
    lr = 0.1

    return ie
}

image_encoder_free :: proc(ie: ^Image_Encoder) {
    using ie

    sdr_free(h)

    delete(weights)

    delete(sums)

    free(ie)
}

image_encoder_step :: proc(ie: ^Image_Encoder, input: []u8, learn_enabled: bool = true) -> SDR {
    using ie

    for i in 0..<h.n {
        sum := 0

        for j in 0..<m do sum += weights[j + i * m] * input[j]

        sums[i] = sum
    }

    sdr_inhibit(h, sums)

    // Learn
    for i in 0..<h.p {
        for j in 0..<m {
            index := j + i * m

            weights[index] = max(0, int(weights[index]) + int(math.round(lr * min(0.0, f32(input[j]) - f32(weights[index])))))
        }
    }

    return h
}
