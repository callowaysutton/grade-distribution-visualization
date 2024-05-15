using Pkg

Pkg.add(["CSV", "DataFrames", "Plots", "PlotlyJS"])

# Read from the grades.csv file
using CSV
using DataFrames
using Plots
using PlotlyJS
using Printf

plotlyjs()

file_path = "data/FA19.csv"

df = CSV.read(file_path, DataFrame)

# Function to safely parse the gpa GPA Grades, and the A+, A, A-, etc. columns
function safe_parse(df)
    parsed_values = tryparse.(Int64, df[!, "GPA Grades"])
    valid_rows = map(x -> x !== nothing, parsed_values)
    df[valid_rows, :]
end

df = safe_parse(df)

# Convert GPA Grades to Int64
df[!, "GPA Grades"] = parse.(Int64, df[!, "GPA Grades"])
df[!, "Total Grades"] = parse.(Int64, df[!, "Total Grades"])
df[!, "Avg Class Grade"] = parse.(Float64, df[!, "Avg Class Grade"])

groups = unique(df[!, "Academic Group Code"])

# Sum the number of students, based off the GPA Grades, for each group
group_student_counts = Dict{String, Int}()
group_average_gpa = Dict{String, Float64}()
for group in groups
    group_df = filter(row -> row."Academic Group Code" == group, df)
    student_count = sum(group_df[!, "GPA Grades"])
    group_average_gpa[group] = mean(group_df[!, "Avg Class Grade"])
    group_student_counts[group] = student_count
end

# Get the maps for a group to its departments
group_department_maps = Dict{String, Array{String, 1}}()
for group in groups
    group_df = filter(row -> row."Academic Group Code" == group, df)
    departments = unique(group_df[!, "Department Code"])
    group_department_maps[group] = departments
end

department_student_counts = Dict{String, Int}()
department_average_gpa = Dict{String, Float64}()

# Sum the number of students, based off the GPA Grades, for each department in each group
for (group, departments) in group_department_maps
    for department in departments
        department_df = filter(row -> row."Department Code" == department && row."Academic Group Code" == group, df)
        student_count = sum(department_df[!, "GPA Grades"])

        # Set the key to the department and the group so that it is unique
        department_student_counts["$group $department"] = student_count
        department_average_gpa["$group $department"] = mean(department_df[!, "Avg Class Grade"])
    end
end

subject_student_counts = Dict{String, Int}()

# Sum the number of students, based off the GPA Grades, for each subject in each department in each group
for (group, departments) in group_department_maps
    for department in departments
        department_df = filter(row -> row."Department Code" == department && row."Academic Group Code" == group, df)
        subjects = unique(department_df[!, "Course Subject"])
        for subject in subjects
            subject_df = filter(row -> row."Course Subject" == subject && row."Department Code" == department && row."Academic Group Code" == group, df)
            student_count = sum(subject_df[!, "GPA Grades"])

            # Set the key to the subject, department, and the group so that it is unique
            subject_student_counts["$group $department-$subject"] = student_count
            department_average_gpa["$group $department-$subject"] = mean(subject_df[!, "Avg Class Grade"])
        end
    end
end

println(department_student_counts)

class_student_counts = Dict{String, Int}()

# Sum the number of students, based off the GPA Grades, for each class in each subject in each department in each group
for (group, departments) in group_department_maps
    for department in departments
        department_df = filter(row -> row."Department Code" == department && row."Academic Group Code" == group, df)
        subjects = unique(department_df[!, "Course Subject"])
        for subject in subjects
            subject_df = filter(row -> row."Course Subject" == subject && row."Department Code" == department && row."Academic Group Code" == group, df)
            classes = unique(subject_df[!, "Catalog Number"])
            for class in classes
                class_df = filter(row -> row."Catalog Number" == class && row."Course Subject" == subject && row."Department Code" == department && row."Academic Group Code" == group, df)
                student_count = sum(class_df[!, "GPA Grades"])

                # Set the key to the class, subject, department, and the group so that it is unique
                class_student_counts["$group $department-$subject-$class"] = student_count
                department_average_gpa["$group $department-$subject-$class"] = mean(class_df[!, "Avg Class Grade"])
            end
        end
    end
end

# Format the parents and labels for the treemap
labels = []
parents = []
colors = []

group_average_gpa
for (group, departments) in group_department_maps
    push!(parents, "Courses")
    push!(labels, group)
    push!(colors, group_average_gpa[group])
    for department in departments
        push!(labels, "$group $department")
        push!(parents, group)
        push!(colors, department_average_gpa["$group $department"])

        # Get the subjects for the department
        department_df = filter(row -> row."Department Code" == department && row."Academic Group Code" == group, df)
        for subject in unique(department_df[!, "Course Subject"])
            push!(labels, "$group $department-$subject")
            push!(parents, "$group $department")
            push!(colors, department_average_gpa["$group $department-$subject"])

            # Get the classes for the subject
            subject_df = filter(row -> row."Course Subject" == subject && row."Department Code" == department && row."Academic Group Code" == group, df)
            for class in unique(subject_df[!, "Catalog Number"])
                push!(labels, "$group $department-$subject-$class")
                push!(parents, "$group $department-$subject")
                push!(colors, department_average_gpa["$group $department-$subject-$class"])
            end
        end
    end
end

# Format the values for the treemap
all_values = []
for (group, student_count) in group_student_counts
    push!(all_values, student_count)
    # println(group)
    # println(group_student_counts[group])

    for department in group_department_maps[group]
        # println("\t$department")
        # println("\t" * string(department_student_counts["$group $department"]))
        push!(all_values, department_student_counts["$group $department"])

        department_df = filter(row -> row."Department Code" == department && row."Academic Group Code" == group, df)
        for subject in unique(department_df[!, "Course Subject"])
            # println("\t\t$subject")
            # println("\t\t" * string(subject_student_counts["$group $department-$subject"]))
            push!(all_values, subject_student_counts["$group $department-$subject"])

            subject_df = filter(row -> row."Course Subject" == subject && row."Department Code" == department && row."Academic Group Code" == group, df)
            for class in unique(subject_df[!, "Catalog Number"])
                # println("\t\t\t$class")
                # println("\t\t\t" * string(class_student_counts["$group $department-$subject-$class"]))
                push!(all_values, class_student_counts["$group $department-$subject-$class"])
            end
        end
    end
end

function gpa_to_hex(gpa)
    t = gpa / 4.0
    t_non_linear = t ^ 2
    R = round(Int, 255 * (1 - t_non_linear))
    G = round(Int, 255 * t_non_linear)
    B = 0
    return @sprintf("#%02X%02X%02X", R, G, B)
end

colors = [round(val, digits=2) for val in colors]

layout = Layout(
    paper_bgcolor="rgb(255,0,0)",
    plot_bgcolor="rgb(255,0,0)"
)

tree = treemap(
    labels = labels,
    parents = parents,
    root_color="lightgrey",
    values = all_values,
    branchvalues = "total",
    textinfo = "label+value",
    marker_colors = map(gpa_to_hex, colors),
    customdata = colors,
    hovertemplate = "<b>%{label}</b><br>People: %{value}<br>Average GPA: %{customdata}<extra></extra>",
    layout = layout
)

tree = PlotlyJS.plot(tree)


# Save the treemap to an HTML file
PlotlyJS.savefig(tree, "index.html")