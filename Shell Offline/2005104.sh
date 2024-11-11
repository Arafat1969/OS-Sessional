#!/bin/bash

input_file="$2"

mapfile -t inputs < "$input_file"

is_archived="${inputs[0]}"
archived_format="${inputs[1]}"

IFS=' ' read -r -a formats <<< "$archived_format"

allowed_language="${inputs[2]}"

IFS=' ' read -r -a languages <<< "$allowed_language"

total_marks=${inputs[3]}
penalty_unmatched=${inputs[4]}
working_directory="${inputs[5]}"
student_id_range="${inputs[6]}"

IFS=' ' read -r -a rangeID <<< "$student_id_range"

expected_output_file="${inputs[7]}"
penalty_guidelines=${inputs[8]}
plagiarism_file="${inputs[9]}"
penalty_plagiarism=${inputs[10]}

validate_input_file(){

	if [[ "$is_archived" != "true" && "$is_archived" != "false" ]]; then
        echo "Error: First line must be 'true' or 'false'."
        return 1
    fi

	for format in "${!formats[@]}"
	do
		if [[ "$format" == "" ]]; then
            echo "Error: No value in second line."
            exit 1
        fi
	done

	for language in "${!languages[@]}"
	do
		if [[ "$language" == "" ]]; then
            echo "Error: No value in third line."
            exit 1
        fi
	done

	if ! [[ "$total_marks" =~ ^[0-9]+$ ]]; then
        echo "Error: Third line must be a valid number."
        return 1
	elif [[ "$total_marks" -lt 0 ]];then
		echo "Error: total marks cannot be negative."
        return 1
    fi


    if ! [[ "$penalty_unmatched" =~ ^[0-9]+$ ]]; then
        echo "Error: Penalty for Unmatched/Non-existent Output must be a valid number."
        return 1
    elif [[ "$penalty_unmatched" -ge "$total_marks" ]]; then
        echo "Error: Penalty for Unmatched/Non-existent Output must be less than the total marks "
        return 1
    fi

	if [[ ! -d "$working_directory" ]]; then
        echo "Error: '$working_directory' is not a valid directory."
        return 1
    fi

	#echo "$expected_output_file"
	if [[ ! -f "$expected_output_file" || "${expected_output_file##*.}" != "txt" ]]; then
        echo "Error: Expected output file is not a valid .txt file."
        return 1
    fi

	if ! [[ "$penalty_guidelines" =~ ^[0-9]+$ ]]; then
        echo "Error: Penalty for Submission Guidelines Violations must be a valid number."
        return 1
	elif [[ "$penalty_guidelines" -ge "$total_marks" ]]; then
		echo "Penalty for Submission Guidelines Violations must be less than Total marks."
		return 1
    fi

	if [[ ! -f "$plagiarism_file" || "${plagiarism_file##*.}" != "txt" ]]; then
        echo "Error: Plagiarism file is not a valid .txt file."
        return 1
    fi

    
    if ! [[ "$penalty_plagiarism" =~ ^[0-9]+$ ]]; then
        echo "Error: Plagiarism Penalty must be a valid number."
        return 1
	elif [[ "$penalty_plagiarism" -gt "$total_marks" ]]; then 
		echo "Error: Penalty for Plagiarism Guidelines Violations must be less than Total marks."
		return 1
    fi

	echo "Input file is valid."
    return 0
}


check_student_id(){
	local filename="$1"
	local student_id="$2"

	if [[ "$filename" == *"$student_id"* ]]; then
		return 0
	else
		return 1
	fi
}


check_language(){
    extension="$1"
	#echo "$extension"
    for lang in "${languages[@]}"; do
        if [[ "$extension" == *"$lang"* ]]; then
            return 0 
        fi
    done
    return 1  
}


create_directories() {

	dir="$1"
    
    if [[ ! -d "$working_directory/$dir" ]]; then
		mkdir "$working_directory/$dir"
	fi
}

move_to_directory() {
    local student_id="$1"
    local status="$2"
    local directory="$working_directory/$status"

    if [[ ! -d "$directory" ]]; then
        create_directories "$status"
    fi

    mv "$working_directory/$student_id" "$directory/"
}

process_plagiarism() {
    local student_id="$1"
    local deductions="$2"
    local remarks="$3"
    local submission_dir="$working_directory/$student_id"

    if grep -q "$student_id" "$plagiarism_file"; then
        deductions=$((deductions + penalty_plagiarism))
        remarks+=" plagiarism detected"
        move_to_directory "$student_id" "issues"
    else
        move_to_directory "$student_id" "checked"
    fi
}



run_program() {
	local student_id="$1"
    local file="$2"
    local output_file="$working_directory/$student_id/${student_id}_output.txt"
    extension="${file##*.}"

	if [[ "$extension" == "py" ]]; then
		python3 "$working_directory/$student_id/$file" > "$output_file"
	elif [[ "$extension" == "c" ]]; then
		gcc "$working_directory/$student_id/$file" -o "$working_directory/$student_id/a.out" && \
			"$working_directory/$student_id/a.out" > "$output_file"
	elif [[ "$extension" == "cpp" ]]; then
		g++ "$working_directory/$student_id/$file" -o "$working_directory/$student_id/a.out" && \
				"$working_directory/$student_id/a.out" > "$output_file"
	elif [[ "$extension" == "bash" ]]; then
		"$working_directory/$student_id/$file" > "$output_file"
	elif [[ "$extension" == "javac" ]]; then
		javac "$working_directory/$student_id/$file"
			  		className=$(basename "$file" .java)
		java -cp "$working_directory/$student_id" "$className" > "$output_file"
	fi
}

write_to_csv() {
    local student_id="$1"
    local final_marks="$2"
    local deducted_marks="$3"
    local total_marks="$4"
    local remarks="$5"
    
    # Check if the file exists, if not create and add headers
    if [[ ! -f "$working_directory/marks.csv" ]]; then
        echo "id,marks,marks_deducted,total_marks,remarks" > "$working_directory/marks.csv"
    fi

    # Append the student's results to the CSV file
    echo "$student_id,$final_marks,$deducted_marks,$total_marks,$remarks" >> "$working_directory/marks.csv"
}


compare_output() {
    local student_id="$1"
    local generated_output="$working_directory/$student_id/${student_id}_output.txt"
    local deducted_marks="$2"
    local remarks="$3"

    if [[ ! -f "$generated_output" ]]; then
        echo "No generated output found for student $student_id."
        remarks="No output file."
        deducted_marks=$total_marks
    else
        while IFS= read -r expected_line; do
            if ! grep -qF "$expected_line" "$generated_output"; then
                echo "Missing line: $expected_line"
                deducted_marks=$((deducted_marks + penalty_unmatched))
                remarks="Output mismatch"
            fi
        done < "$expected_output_file"
    fi

    local final_marks=$((total_marks - deducted_marks))
    if [[ $final_marks -lt 0 ]]; then
        final_marks=0
    fi

    
    write_to_csv "$student_id" "$final_marks" "$deducted_marks" "$total_marks" "$remarks"

    echo "Final marks for student $student_id: $final_marks"
}


process_submission(){
	local submission_file="$1"
	local student_id="$2"
	deducted_marks=0
	extension="${submission_file##*.}"
	base_name="${submission_file%.*}"
	remarks=""
	
	is_compressed=false

	for ext in "${formats[@]}"; do 
		if [[ "$extension" == "$ext" ]]; then
			is_compressed=true
			break
	done

	if [[ $is_compressed ]]; then
		if [[ "$extension" == "zip" ]]; then
			unzip "$submission_file" -d "$working_directory/" > /dev/null 2>&1 
		elif [[ "$extension" == "rar" ]]; then
			unrar x "$submission_file" "$working_directory/" > /dev/null 2>&1 
		elif [[ "$extension" == "tar" ]]; then
			tar -xf "$submission_file" -C "$working_directory/" > /dev/null 2>&1 
		fi
	elif [[ -d "$submission_file" ]]; then
		echo "Already directory...no need to create"
		remarks="Issue case #1: Submission is a folder."
		move_to_directory "issues"
	elif [[ -f "$submission_file" ]]
		if [ ! -d "$base_name" ]; then
			echo "Creating directory: $base_name"
			mkdir "$base_name"
		else
			echo "Directory $base_name already exists."
		fi

			mv "$submission_file" "$base_name/"
	else
		deducted_marks=$((deducted_marks + penalty_guidelines))
		remarks="Issue case #2: Invalid archive format."
		move_to_directory "issues"
		return
	fi


	file=$(ls "$working_directory/$student_id/" 2> /dev/null)

	echo "$file"
	filename="${file%.*}"
	file_ext="${file##*.}"
	echo "$file_ext"

	if ! check_student_id "$filename" "$student_id"; then
		echo "Warning: File $filename does not match the student ID $student_id"
		deducted_marks=$((deducted_marks + penalty_guidelines))
    	remarks="Issue case #4: Folder name does not match student ID."
		move_to_directory "issues"
		return
	fi

	if ! check_language "$file_ext"; then
		echo "Warning: File $file_ext is not in an allowed language."
		deducted_marks=$((deducted_marks + penalty_guidelines))
		remarks="Issue case #3: Invalid programming language."
		move_to_directory "issues"
		return
	fi

	run_program "$student_id" "$file"

	process_plagiarism "$student_id" "$deducted_marks" "$remarks"

	compare_output "$student_id" "$deducted_marks" "$remarks" 

	move_to_directory "checked"
	

}




validate_input_file 

for submission in "$working_directory"/*; do
	submission_file=$(basename "$submission")
	student_id="${submission_file%%.*}" 
	
	if [[ "$student_id" -lt "${rangeID[0]}" || "$student_id" -gt "${rangeID[1]}" ]]; then
		continue
	fi

	echo "Processing submission for student ID: $student_id"
	process_submission "$submission" "$student_id"
done