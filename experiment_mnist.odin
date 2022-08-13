package main

import "core:fmt"
import "core:math/rand"
import "core:intrinsics"
import "core:os"
import "core:strings"

import tri "triadic"

MNIST_NUM_ITEMS :: 60000
MNIST_IMAGE_SIZE :: 28 * 28

when EXPERIMENT == "mnist" {
    MNIST_Dataset :: struct {
        labels: []u8,
        images: []u8,
    }

    mnist_new_train :: proc() -> (MNIST_Dataset, bool) {
        dataset := MNIST_Dataset{ make([]u8, MNIST_NUM_ITEMS), make([]u8, MNIST_NUM_ITEMS * 28 * 28) }

        label_data, label_ok := os.read_entire_file_from_filename("train-labels-idx1-ubyte")

        if !label_ok {
            return dataset, false
        }

        defer delete(label_data)

        image_data, image_ok := os.read_entire_file_from_filename("train-images-idx3-ubyte")

        if !image_ok {
            return dataset, false
        }

        defer delete(image_data)

        for i in 0..<MNIST_NUM_ITEMS {
            dataset.labels[i] = label_data[i + 8]

            image_start := i * MNIST_IMAGE_SIZE + 16

            for j in 0..<MNIST_IMAGE_SIZE do dataset.images[j + i * MNIST_IMAGE_SIZE] = image_data[j + image_start]    
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
        dataset, ok := mnist_new_train()

        if !ok {
            fmt.println("Could not open dataset!")
            return
        }

        defer mnist_free(dataset)

        nx: int = 512
        ny: int = 256
        p: int = 4

        rng: rand.Rand = rand.create(u64(intrinsics.read_cycle_counter()))

        randomize_buffer := make([]int, ny)
        tri.randomize_buffer_init(randomize_buffer)
        defer delete(randomize_buffer)

        dm := tri.diadic_memory_new(nx, ny, p)
        defer tri.diadic_memory_free(dm)

        ie := tri.image_encoder_new(MNIST_IMAGE_SIZE, nx, p, &rng)
        defer tri.image_encoder_free(ie)

        label_sdrs: [10]tri.SDR

        for t in 0..<len(label_sdrs) do label_sdrs[t] = tri.sdr_new_random(ny, p, randomize_buffer, &rng)

        defer for t in 0..<len(label_sdrs) {
            tri.sdr_free(label_sdrs[t])
        }

        fmt.println("Training...")

        num_iterations: int = 10000

        for it in 0..<num_iterations {
            if it % 100 == 99 do fmt.printf("Iteration %d/%d\n", it, num_iterations)
            
            rand_index := int(rand.uint32(&rng) % MNIST_NUM_ITEMS)

            label := dataset.labels[rand_index]
            img := mnist_get_image(dataset, rand_index)

            tri.image_encoder_step(ie, img, true)

            tri.diadic_memory_add(dm, ie.h, label_sdrs[label])
        }

        fmt.println("Recall:")

        pred := tri.sdr_new(ny, p)
        defer tri.sdr_free(pred)

        num_test: int = 1000
        test_errors: int = 0

        for t in 0..<num_test {
            rand_index := int(rand.uint32(&rng) % MNIST_NUM_ITEMS)

            label := dataset.labels[rand_index]
            img := mnist_get_image(dataset, rand_index)

            tri.image_encoder_step(ie, img, false)

            tri.diadic_memory_read_y(dm, ie.h, &pred)

            // Search labels
            min_dist: int = ny
            min_index: u8 = 0

            for v, i in label_sdrs {
                dist := tri.sdr_distance(pred, v) 

                if dist < min_dist {
                    min_dist = dist
                    min_index = u8(i)
                }
            }

            if min_index != label do test_errors += 1
        }

        fmt.printf("Errors: %d/%d Accuracy: %f\n", test_errors, num_test, 1.0 - f32(test_errors) / f32(num_test))
    }
}
