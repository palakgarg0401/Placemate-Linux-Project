#!/bin/bash

#File Paths
STUDENTS_FILE="students.txt"
LOG_FILE="student_mgmt.log"

#Check for required files
[[ ! -f "$STUDENTS_FILE" ]] && touch "$STUDENTS_FILE"
[[ ! -f "LOG_FILE" ]] && touch "$LOG_FILE"

#Main Menu Funstion
main_menu() {
    while true; do
        CHOICE=$(dialog --backtitle "PLACEMATE" \
            --title "STUDENT PLACEMENT SYSTEM" \
            --menu "Choose an option:" 15 50 6 \
            1 "Add Student Record" \
            2 "Delete Student Record" \
            3 "Modify Student Record" \
            4 "View All Student Records" \
            5 "Assign Company to Student" \
            6 "Search Student by Roll No" \
            7 "Filter By Branch" \
            8 "Filter By CGPA" \
            9 "Exit" \
            3>&1 1>&2 2>&3)

        if [[ -z "$CHOICE" ]]; then
            clear
            exit
        fi

        case $CHOICE in
            1) add_student ;;
            2) delete_student ;;
            3) modify_student ;;
            4) view_students ;;
            5) assign_company ;;
            6) search_student ;;
            7) filter_by_branch ;;
            8) filter_by_cgpa ;;
            9) clear; exit ;;
        esac
    done
}

#Placeholder Functions (to be implemented)
add_student() {
    # Prompt for student details using dialog
    ROLL=$(dialog --inputbox "Enter Roll Number:" 8 40 3>&1 1>&2 2>&3)
    [[ -z "$ROLL" ]] && return

    # Check for duplicate roll number
    if grep -q "^$ROLL:" "$STUDENTS_FILE"; then
        dialog --msgbox "Roll number alread exists!" 6 40
        return
    fi

    NAME=$(dialog --inputbox "Enter Student Name:" 8 40 3>&1 1>&2 2>&3)
    [[ -z "$NAME" ]] && return

    BRANCH=$(dialog --inputbox "Enter Branch (e.g., CSE, ECE):" 8 40 3>&1 1>&2 2>&3)
    [[ -z "$BRANCH" ]] && return

    CGPA=$(dialog --inputbox "Enter CGPA (0.0 - 10.0):" 8 40 3>&1 1>&2 2>&3)
    [[ -z "CGPA" ]] && return

    if ! echo "$CGPA" | grep -Eq '^[0-9]+(\.[0-9]+)?$' || (( $(echo "$CGPA < 0 || $CGPA > 10" | bc -1) )); then
        dialog --msgbox "Invalid CGPA. Must be a number between 0 and 10." 6 50
        return
    fi

    #Default empty company (can be updated later)
    COMPANY=""

    # Save to file
    echo "$ROLL:$NAME:$BRANCH:$CGPA:$COMPANY" >> "$STUDENTS_FILE"

    # Log action
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Added student: $ROLL $NAME $BRANCH $CGPA" >> "$LOG_FILE"

    # Confirmation
    dialog --msgbox "Student record added successfully!" 6 40
}

delete_student() {
    # Ask for roll number to delete
    ROLL=$(dialog --inputbox "Enter Roll Number to delete:" 8 40 3>&1 1>&2 2>&3)
    ROLL=$(echo "$ROLL" | xargs) # Trim Whitespace
    [[ -z "$ROLL" ]] && return

    # Check if the student exists
    if ! grep -q "^$ROLL:" "$STUDENTS_FILE"; then
        dialog --msgbox "Student with Roll No. $ROLL not found." 6 40
        return
    fi

    # Confirm deletion
    dialog --yesno "Are you sure you want to delete Roll No. $ROLL?" 7 50
    [[ $? -ne 0 ]] && return

    # Delete the record
    grep -v "^$ROLL:" "$STUDENTS_FILE" > temp.txt
    mv temp.txt "$STUDENTS_FILE"

    # Log action
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Deleted student with Roll No: $ROLL" >> "$LOG_FILE"

    # Notify success
    dialog --msgbox "Student record deleted successfully!" 6 40
}

modify_student() {
    ROLL=$(dialog --inputbox "Enter Roll Number to modify:" 8 40 3>&1 1>&2 2>&3)
    ROLL=$(echo "$ROLL" | xargs)
    [[ -z "$ROLL" ]] && return

    # Check if student exists
    STUDENT_LINE=$(grep "^$ROLL:" "$STUDENTS_FILE")
    if [[ -z "$STUDENT_LINE" ]]; then
        dialog --msgbox "Student with Roll No. $ROLL not found." 6 40
        return
    fi

    # Extract current values
    NAME=$(echo "$STUDENT_LINE" | cut -d':' -f2)
    BRANCH=$(echo "$STUDENT_LINE" | cut -d':' -f3)
    CGPA=$(echo "$STUDENT_LINE" | cut -d':' -f4)
    COMPANY=$(echo "$STUDENT_LINE" | cut -d':' -f5)

    # Ask for new details
    NAME_NEW=$(dialog --inputbox "Edit Name:" 8 40 "$NAME" 3>&1 1>&2 2>&3)
    BRANCH_NEW=$(dialog --inputbox "Edit Branch:" 8 40 "$BRANCH" 3>&1 1>&2 2>&3)
    CGPA_NEW=$(dialog --inputbox "Edit CGPA (0-10):" 8 40 "$CGPA" 3>&1 1>&2 2>&3)

    # Basic validation for CGPA
    if ! echo "$CGPA_NEW" | grep -Eq '^([0-9](\.[0-9]+)?|10(\.0+)?)$'; then
        dialog --msgbox "Invalid CGPA value. Please enter a number between 0 and 10." 6 50
        return
    fi

    # Construct new record
    NEW_LINE="$ROLL:$NAME_NEW:$BRANCH_NEW:$CGPA_NEW:$COMPANY"

    # Replace old line with new
    sed -i "s/^$ROLL:.*/$NEW_LINE/" "$STUDENTS_FILE"

    # Log the action
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Modified student: $ROLL" >> "$LOG_FILE"

    dialog --msgbox "Student record updated successfully!" 6 40
}


view_students() {
    if [[ ! -s "$STUDENTS_FILE" ]]; then
        dialog --msgbox "No student records found." 6 40
        return
    fi

    TEMP_FILE=$(mktemp)

    echo -e "ROLL\tNAME\t\tBRANCH\tCGPA\tCOMPANY" > "$TEMP_FILE"
    echo "--------------------------------------------------------" >> "$TEMP_FILE"
    awk -F':' '{printf "%s\t%-15s%-8s%s\t%s\n", $1, $2, $3, $4, $5}' "$STUDENTS_FILE" >> "$TEMP_FILE"

    dialog --title "All Student Records" --textbox "$TEMP_FILE" 20 70

    rm -f "$TEMP_FILE"
}

assign_company() {
    ROLL=$(dialog --inputbox "Enter Roll Number to assign company:" 8 40 3>&1 1>&2 2>&3)
    ROLL=$(echo "$ROLL" | xargs)
    [[ -z "$ROLL" ]] && return

    STUDENT_LINE=$(grep "^$ROLL:" "$STUDENTS_FILE")
    if [[ -z "$STUDENT_LINE" ]]; then
        dialog --msgbox "Student with Roll No. $ROLL not found." 6 40
        return
    fi

    CURRENT_COMPANY=$(echo "$STUDENT_LINE" | cut -d':' -f5)
    NEW_COMPANY=$(dialog --inputbox "Enter Company Name:" 8 40 "$CURRENT_COMPANY" 3>&1 1>&2 2>&3)
    NEW_COMPANY=$(echo "$NEW_COMPANY" | xargs)

    [[ -z "$NEW_COMPANY" ]] && dialog --msgbox "Company name cannot be empty!" 6 40 && return

    # Update the record
    NAME=$(echo "$STUDENT_LINE" | cut -d':' -f2)
    BRANCH=$(echo "$STUDENT_LINE" | cut -d':' -f3)
    CGPA=$(echo "$STUDENT_LINE" | cut -d':' -f4)

    NEW_LINE="$ROLL:$NAME:$BRANCH:$CGPA:$NEW_COMPANY"
    sed -i "s/^$ROLL:.*/$NEW_LINE/" "$STUDENTS_FILE"

    echo "$(date '+%Y-%m-%d %H:%M:%S') - Assigned $NEW_COMPANY to Roll No. $ROLL" >> "$LOG_FILE"

    dialog --msgbox "Company assigned successfully!" 6 40
}

search_student() {
    ROLL=$(dialog --inputbox "Enter Roll Number to search:" 8 40 3>&1 1>&2 2>&3)
    ROLL=$(echo "$ROLL" | xargs)
    [[ -z "$ROLL" ]] && return

    STUDENT_LINE=$(grep "^$ROLL:" "$STUDENTS_FILE")
    if [[ -z "$STUDENT_LINE" ]]; then
        dialog --msgbox "No student found with Roll No. $ROLL" 6 40
        return
    fi

    NAME=$(echo "$STUDENT_LINE" | cut -d':' -f2)
    BRANCH=$(echo "$STUDENT_LINE" | cut -d':' -f3)
    CGPA=$(echo "$STUDENT_LINE" | cut -d':' -f4)
    COMPANY=$(echo "$STUDENT_LINE" | cut -d':' -f5)

    dialog --msgbox "📄 Student Details:\n\nRoll No: $ROLL\nName: $NAME\nBranch: $BRANCH\nCGPA: $CGPA\nCompany: $COMPANY" 12 50
}

filter_by_branch() {
    BRANCH=$(dialog --inputbox "Enter branch to filter (e.g., CSE, ECE):" 8 40 3>&1 1>&2 2>&3)
    BRANCH=$(echo "$BRANCH" | xargs)
    [[ -z "$BRANCH" ]] && return

    TEMP_FILE=$(mktemp)

    MATCHED=$(grep -i ":.*:$BRANCH:" "$STUDENTS_FILE")
    if [[ -z "$MATCHED" ]]; then
        dialog --msgbox "No records found for branch $BRANCH" 6 40
        rm -f "$TEMP_FILE"
        return
    fi

    echo -e "ROLL\tNAME\t\tBRANCH\tCGPA\tCOMPANY" > "$TEMP_FILE"
    echo "--------------------------------------------------------" >> "$TEMP_FILE"
    echo "$MATCHED" | awk -F':' '{printf "%s\t%-15s%-8s%s\t%s\n", $1, $2, $3, $4, $5}' >> "$TEMP_FILE"

    dialog --title "Students in $BRANCH" --textbox "$TEMP_FILE" 20 70
    rm -f "$TEMP_FILE"
}

filter_by_cgpa() {
    CGPA_THRESHOLD=$(dialog --inputbox "Enter minimum CGPA (0–10):" 8 40 3>&1 1>&2 2>&3)
    CGPA_THRESHOLD=$(echo "$CGPA_THRESHOLD" | xargs)
    [[ -z "$CGPA_THRESHOLD" ]] && return

    if ! [[ $CGPA_THRESHOLD =~ ^[0-9]+(\.[0-9]+)?$ ]] || (( $(echo "$CGPA_THRESHOLD < 0 || $CGPA_THRESHOLD > 10" | bc -l) )); then
        dialog --msgbox "Invalid CGPA input. Please enter a value between 0 and 10." 6 50
        return
    fi

    TEMP_FILE=$(mktemp)

    MATCHED=$(awk -F':' -v cg="$CGPA_THRESHOLD" '$4 >= cg' "$STUDENTS_FILE")
    if [[ -z "$MATCHED" ]]; then
        dialog --msgbox "No students found with CGPA >= $CGPA_THRESHOLD" 6 50
        rm -f "$TEMP_FILE"
        return
    fi

    echo -e "ROLL\tNAME\t\tBRANCH\tCGPA\tCOMPANY" > "$TEMP_FILE"
    echo "--------------------------------------------------------" >> "$TEMP_FILE"
    echo "$MATCHED" | awk -F':' '{printf "%s\t%-15s%-8s%s\t%s\n", $1, $2, $3, $4, $5}' >> "$TEMP_FILE"

    dialog --title "Students with CGPA >= $CGPA_THRESHOLD" --textbox "$TEMP_FILE" 20 70
    rm -f "$TEMP_FILE"
}

# Run the menu
main_menu
