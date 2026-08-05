// Adapter from Cython's range callback to oneTBB's templated parallel_for.

#pragma once

#include <cstddef>

#include <oneapi/tbb/blocked_range.h>
#include <oneapi/tbb/parallel_for.h>
#include <oneapi/tbb/task_arena.h>

// Body of one chunk of rays: [begin, end).
typedef void (*embreex_range_fn)(void *ctx, size_t begin, size_t end);

// Apply fn to subranges of [0, n); grain controls divisibility. nthreads > 0
// caps concurrency via task_arena; nthreads == 0 uses the TBB default pool
// (Open3D RaycastingScene semantics).
inline void embreex_parallel_for(size_t n,
                                 size_t grain,
                                 int nthreads,
                                 embreex_range_fn fn,
                                 void *ctx) {
    auto body = [&](const tbb::blocked_range<size_t> &r) {
        fn(ctx, r.begin(), r.end());
    };
    const tbb::blocked_range<size_t> range(0, n, grain);

    if (nthreads > 0) {
        tbb::task_arena arena(nthreads);
        arena.execute([&]() { tbb::parallel_for(range, body); });
    } else {
        tbb::parallel_for(range, body);
    }
}
