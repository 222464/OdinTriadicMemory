package main

import "core:fmt"
import "core:math/rand"
import "core:intrinsics"
import "core:os"
import "core:strings"

import tri "triadic"

MNIST_NUM_ITEMS :: 60000
MNIST_IMAGE_SIZE = 28 * 28

when EXPERIMENT == "mnist" {
    MNIST_Dataset :: struct {
        labels: []u8,
        images: []u8,
    }

    mnist_new_train :: proc() -> (MNIST_Dataset, bool) {
        dataset := MNIST_Dataset{ make([]u8, MNIST_NUM_ITEMS), make([]u8, MNIST_NUM_ITEMS * 28 * 28) }

        label_data, ok := os.read_entire_file_from_filename("train-labels-idx1-ubyte")

        if !ok {
            return nil, false
        }

        defer delete(label_data)

        image_data, ok := os.read_entire_file_from_filename("train-images-idx3-ubyte")

        if !ok {
            return nil, false
        }

        defer delete(image_data)

        for i in 0..<MNIST_NUM_ITEMS {
            labels[i] = label_data[i + 8]

            image_start := i * MNIST_IMAGE_SIZE + 16

            for j in 0..<MNIST_IMAGE_SIZE do images[j + i * MNIST_IMAGE_SIZE] = image_data[j + image_start]    
        }

        return dataset, true
    }

    mnist_get_image :: proc(dataset: MNIST_Dataset, index: int) -> []u8 {
        image_start := index * MNIST_IMAGE_SIZE

        return dataset.images[image_start : image_start + MNIST_IMAGE_SIZE]
    }

    mnist_free :: proc(dataset: MNIST_Dataset) {
        using dataset

        delete(labels)
        delete(images)
    }

    main :: proc() {
        dataset, ok = mnist_new_train()

        if !ok {
            fmt.println("Could not open dataset!")
            return
        }

        defer mnist_free(dataset)

        n: int = 1024
        p: int = 8

        rng: rand.Rand = rand.create(u64(intrinsics.read_cycle_counter()))

        tm := tri.temporal_memory_new(n, p)
        defer tri.triadic_memory_free(tm)

        label_sdrs: [10]tri.SDR

        for t in 0..<len(label_sdrs) do char_sdrs[t] = tri.sdr_new_random(n, p, ttm.randomize_buffer, &rng)

        defer for t in 0..<len(label_sdrs) {
            tri.sdr_free(label_sdrs[t])
        }

        // Read the data
        data, ok := os.read_entire_file_from_filename("corpus.txt")

        if !ok {
            fmt.println("Could not open file!")
            return
        }

        fmt.println("Training...")

        num_iterations: int = 10

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
}
