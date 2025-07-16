using DataFramesMeta

# Create a sample DataFrame
df = DataFrame(x = [1, 1, 2, 2], y = [1, 2, 101, 102])

# @select - Select columns
@select(df, :x, :y)  # Select specific columns
@select(df, :x2 = 2 * :x, :y)  # Select and transform

# @transform - Add or modify columns
@transform(df, :z = :x + :y)  # Add a new column
@transform(df, :x = :x * 2)  # Modify existing column

# @subset - Filter rows
@subset(df, :x .> 1)  # Keep rows where x > 1
@subset(df, :x .> 1, :y .< 102)  # Multiple conditions

# @orderby - Sort rows
@orderby(df, :x)  # Sort by x ascending
@orderby(df, -:x, :y)  # Sort by x descending, then y ascending

# @groupby and @combine - Group and summarize
gdf = @groupby(df, :x)
@combine(gdf, :mean_y = mean(:y))  # Compute mean of y for each group

# @by - Group and summarize in one step
@by(df, :x, :mean_y = mean(:y))

# Row-wise operations with @byrow
@transform(df, @byrow :z = :x == 1 ? true : false)

# @rtransform - Row-wise transform
@rtransform(df, :z = :x * :y)

# @rsubset - Row-wise subset
@rsubset(df, :x > 1)

# @with - Use DataFrame columns as variables
@with(df, :x + :y)

# @eachrow - Iterate over rows
@eachrow df begin
    if :x > 1
        :y = :y * 2
    end
end

# @passmissing - Handle missing values
df_missing = DataFrame(a = [1, 2, missing], b = [4, 5, 6])
@transform df_missing @passmissing @byrow :c = :a + :b

# @astable - Create multiple columns at once
@transform df @astable begin
    ex = extrema(:y)
    :y_min = :y .- first(ex)
    :y_max = :y .- last(ex)
end

# AsTable for multiple column operations
@rtransform df :sum_xy = sum(AsTable([:x, :y]))

# $ for programmatic column references
col_name = :x
@transform(df, :new_col = $col_name * 2)

# @chain for piping operations
result = @chain df begin
    @transform(:z = :x * :y)
    @subset(:z > 50)
    @select(:x, :y, :z)
    @orderby(:z)
end

# @label! for adding column labels
@label! df :x = "Group ID"

# @note! for adding column notes
@note! df :y = "Raw measurements"

# Print labels and notes
printlabels(df)
printnotes(df)
