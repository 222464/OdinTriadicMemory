package main

import "core:fmt"
import "core:math/rand"
import "core:intrinsics"
import "core:os"
import "core:strings"

import tri "triadic"

main :: proc() {
    n: int = 256
    p: int = 4

    rng: rand.Rand = rand.create(u64(intrinsics.read_cycle_counter()))

    ttm := tri.temporal_memory_new(n, p)
    defer tri.temporal_memory_free(ttm)

    char_sdrs: [128]tri.SDR

    for t := 0; t < len(char_sdrs); t += 1 do char_sdrs[t] = tri.sdr_new_random(n, p, ttm.randomize_buffer, &rng)

    defer for t := 0; t < len(char_sdrs); t += 1 {
        tri.sdr_free(char_sdrs[t])
    }

    // Read the data
    data, ok := os.read_entire_file_from_filename("corpus.txt")

    if !ok {
        fmt.println("Could not open file!")
        return
    }

    fmt.println("Training...")

    num_iterations: int = 20

    for it := 0; it < num_iterations; it += 1 {
        fmt.printf("Iteration %d/%d\n", it, num_iterations)

        //tri.temporal_memory_flush(ttm)

        for t := 0; t < len(data); t += 1 {
            c := int(data[t])

            tri.temporal_memory_step(ttm, char_sdrs[c], &rng, true)

            if t % 100 == 99 {
                fmt.println(t)
            }
        }
    }

    fmt.println("Recall:")

    //input := tri.sdr_new(n, p)
    //defer tri.sdr_free(input)

    for t := 0; t < 1000; t += 1 {
        // Search characters
        min_dist: int = n
        min_index: int = 0

        for v, i in char_sdrs {
            dist := tri.sdr_distance(ttm.pred, v) 

            if dist < min_dist {
                min_dist = dist
                min_index = i
            }
        }

        fmt.print(rune(min_index))

        tri.temporal_memory_step(ttm, char_sdrs[min_index], &rng, false)
    }
}
