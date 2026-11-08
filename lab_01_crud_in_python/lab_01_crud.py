FILENAME = 'students.txt'

# ---------- CREATE ----------
def insert_student(student_id, name, age, major, gpa):
    """Insert a new student record into the file."""
    with open(FILENAME, 'a') as file:
        file.write(f"{student_id}|{name}|{age}|{major}|{gpa}\n")
    print("Record inserted successfully.\n")


# ---------- READ ----------
def read_students():
    """Read and display all records from the file."""
    try:
        with open(FILENAME, 'r') as file:
            print("Student Records:")
            for line in file:
                if not line.startswith('--'):
                    print(line.strip())
            print()
    except FileNotFoundError:
        print("Database file not found.\n")


# ---------- UPDATE ----------
def update_student(student_id, field, new_value):
    """Update a specific student's field."""
    lines = []
    found = False
    with open(FILENAME, 'r') as file:
        for line in file:
            if line.startswith('--'):
                lines.append(line)
                continue
            data = line.strip().split('|')
            if data[0] == str(student_id):
                found = True
                mapping = {'name':1, 'age':2, 'major':3, 'gpa':4}
                if field in mapping:
                    data[mapping[field]] = str(new_value)
                    print(f"Updated {field} for ID {student_id}.")
                line = '|'.join(data) + '\n'
            lines.append(line)
    if not found:
        print("Record not found.")
    else:
        with open(FILENAME, 'w') as file:
            file.writelines(lines)
        print("Record updated successfully.\n")


# ---------- DELETE ----------
def delete_student(student_id):
    """Delete a student record by ID."""
    with open(FILENAME, 'r') as file:
        lines = file.readlines()

    new_lines = [l for l in lines if not (l.split('|')[0] == str(student_id))]
    
    if len(new_lines) == len(lines):
        print("Record not found.")
    else:
        with open(FILENAME, 'w') as file:
            file.writelines(new_lines)
        print("Record deleted successfully.\n")


# ---------- MENU ----------
def menu():
    while True:
        print("========== Student Database Menu ==========")
        print("1. Insert Student")
        print("2. View All Students")
        print("3. Update Student")
        print("4. Delete Student")
        print("5. Exit")
        choice = input("Enter your choice: ")

        if choice == '1':
            student_id = input("Enter ID: ")
            name = input("Enter Name: ")
            age = input("Enter Age: ")
            major = input("Enter Major: ")
            gpa = input("Enter GPA: ")
            insert_student(student_id, name, age, major, gpa)
        elif choice == '2':
            read_students()
        elif choice == '3':
            student_id = input("Enter ID to update: ")
            field = input("Field to update (name/age/major/gpa): ").lower()
            new_value = input("Enter new value: ")
            update_student(student_id, field, new_value)
        elif choice == '4':
            student_id = input("Enter ID to delete: ")
            delete_student(student_id)
        elif choice == '5':
            print("Exiting program.")
            break
        else:
            print("Invalid choice.\n")

# Run the menu when script is executed
if __name__ == "__main__":
    menu()