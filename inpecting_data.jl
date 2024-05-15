using Pkg

Pkg.add(["CSV", "DataFrames", "Plots"])

# Read from the grades.csv file
using CSV
using DataFrames
using Plots

file_path = "grades.csv"

df = CSV.read(file_path, DataFrame)

# Function to safely parse the gpa grades column
function safe_parse_gpa_grades(df)
    parsed_values = tryparse.(Float64, df[!, "Avg Class Grade"])
    valid_rows = map(x -> x !== nothing, parsed_values)
    df[valid_rows, :]
end

# Print the column names
println(names(df))

df = safe_parse_gpa_grades(df)
df[!, "Avg Class Grade"] = parse.(Float64, df[!, "Avg Class Grade"])

# Find how many groups are in the dataset
unique_teachers = unique(df[!, "Instructor Name"])
unique_departments = unique(df[!, "Department Code"])
unique_academic_groups = unique(df[!, "Academic Group Code"])
classes_with_4_0 = filter(row -> row."Avg Class Grade" == 4.0, df)
classes_with_0 = filter(row -> row."Avg Class Grade" == 0.0, df)
count_of_classes_with_4_0 = length(classes_with_4_0[:, 1])
count_of_classes_with_0 = length(classes_with_0[:, 1])

println("There are ", length(unique_teachers), " unique teachers in the dataset")
println("There are ", length(unique_departments), " unique departments in the dataset")
println("There are ", length(unique_academic_groups), " unique academic groups in the dataset")
println("There are ", count_of_classes_with_4_0, " classes with a 4.0 average grade")

# Remove the rows with a 4.0 average grade with an antijoin
df = antijoin(df, classes_with_4_0, on="Catalog Number")
df = antijoin(df, classes_with_0, on="Catalog Number")

# Count all the classes with a 4.0 average grade

# Make a scatter plot with the Catalog Number as the X and the Avg Class GPA as the Y
scatter(df[!, "Catalog Number"], df[!, "Avg Class Grade"], title="Catalog Number vs Avg Class GPA", xlabel="Catalog Number", ylabel="Avg Class Grade", legend=false)

# Colorize the scatter plot by the Department Code and make it a bit more readable by making it a bit bigger
scatter(df[!, "Catalog Number"], df[!, "Avg Class Grade"], group=df[!, "Department Code"], title="Catalog Number vs Avg Class GPA", xlabel="Catalog Number", ylabel="Avg Class Grade", legend=false, markersize=3)

# Find the highest Class GPA
highest_class_gpa = minimum(df[!, "Avg Class Grade"])

