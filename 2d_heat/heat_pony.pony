use "collections"

// TODO: handle values outside of the main square

actor Main
  let env: Env val
  var grid: Array[Array[F64] val] val
  var new_grid: Array[Array[F64]] ref

  let n: USize = 96
  let n_threads: USize = 2
  let threads: Array[Task] ref
  let epsilon: F64 = 0.0001

  // var grid_res: Array[Array[F64] ref] ref
  var results: USize = 0
  var precision: F64 = 0

  new create(env': Env) =>
    env = env'
    // init
    grid = recover val
      let res: Array[Array[F64] val] ref = Array[Array[F64] val](n)
      for i in Range[USize](0, n) do
        let row: Array[F64] iso = recover iso Array[F64](n) end
        for j in Range[USize](0, n) do
          if i == 0 then
            row.push(1.0)
          else
            row.push(0.0)
          end
        end
        res.push(consume row)
      end
      res
    end

    new_grid = Array[Array[F64]](n)
    for i in Range[USize](0, n) do
      new_grid.push(Array[F64](n))
    end

    threads = Array[Task](n_threads)
    for i in Range[USize](0, n_threads) do
      let task = Task((n / n_threads) * i, (n / n_threads) * (i + 1), this)
      task.start(grid)
      threads.push(task)
    end

    env.out.print("Begin")

  be receive(grid_res': Array[Array[F64] iso] iso, precision': F64) =>
    // Calculate the maximum precision value
    if precision < precision' then
      precision = precision'
    end

    // Copy the non-empty rows to result
    for i in Range[USize](0, n) do
      try
        if grid_res'(i)?.size() > 0 then
          new_grid(i)? = (grid_res'(i)? = recover iso Array[F64](n) end)
        end
      else None end
    end

    // Increment results counter
    results = results + 1

    if results == n_threads then
      iteration_end()
    else
      iteration_start()
    end

  fun ref iteration_start() =>
    env.out.print("New iteration!")
    // restart iterations
    precision = 0
    results = 0

    // Copy new_grid to grid (fancy code to make the type checker happy)
    let new_grid': Array[Array[F64] val] iso = recover iso Array[Array[F64] val](n) end
    for row in new_grid.values() do
      let row': Array[F64] iso = recover iso Array[F64](n) end
      for value in row.values() do
        row'.push(value)
      end
      new_grid'.push(consume row')
    end
    grid = consume new_grid'
    new_grid = Array[Array[F64]](n)
    for i in Range[USize](0, n) do
      new_grid.push(Array[F64](n))
    end

    for thread in threads.values() do
      thread.start(grid)
    end

  fun ref iteration_end() =>
    if precision < epsilon then
      env.out.print("End")
    end

actor Task
  let from: USize
  let to: USize
  let parent: Main tag

  new create(from': USize, to': USize, parent': Main tag) =>
    from = from'
    to = to'
    parent = parent'

  be start(grid: Array[Array[F64] val] val) =>
    // Initialize result array
    let res: Array[Array[F64] iso] iso = recover iso
      let x = Array[Array[F64] iso](grid.size())
      for i in Range[USize](0, grid.size()) do
        x.push(recover iso Array[F64](grid.size()) end)
      end
      x
    end
    var precision: F64 = 0

    for i in Range[USize](from, to) do
      if (i >= 1) and (i < (grid.size() - 1)) then
        try
          let row = grid(i)?
          let rowup = grid(i - 1)?
          let rowdown = grid(i + 1)?

          for j in Range[USize](1, grid.size() - 1) do
            let t: F64 = 0.25 * (rowdown(j)? + rowup(j)? + row(j - 1)? + row(j + 1)?)
            let dt: F64 = (t - row(j)?).abs()
            if precision < dt then
              precision = dt
            end
            res(i)?.push(t)
          end
        end
      end
    end

    parent.receive(consume res, precision)

