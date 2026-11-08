#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define FILENAME "students.txt"

// ---------- CREATE ----------
void insert_student() {
    char id[20], name[50], age[10], major[50], gpa[10];
    FILE *file = fopen(FILENAME, "a");
    if (!file) {
        printf("Error opening file.\n");
        return;
    }

    printf("Enter ID: "); gets(id);
    printf("Enter Name: "); gets(name);
    printf("Enter Age: "); gets(age);
    printf("Enter Major: "); gets(major);
    printf("Enter GPA: "); gets(gpa);

    fprintf(file, "%s|%s|%s|%s|%s\n", id, name, age, major, gpa);
    fclose(file);
    printf("Record inserted successfully.\n\n");
}

// ---------- READ ----------
void read_students() {
    FILE *file = fopen(FILENAME, "r");
    if (!file) {
        printf("Database file not found.\n\n");
        return;
    }

    char line[200];
    printf("Student Records:\n");
    while (fgets(line, sizeof(line), file)) {
        if (strncmp(line, "--", 2) != 0)
            printf("%s", line);
    }
    printf("\n");
    fclose(file);
}

// ---------- UPDATE ----------
void update_student() {
    char id[20], field[20], new_value[50];
    char line[200];
    char tempFile[] = "temp.txt";
    FILE *file = fopen(FILENAME, "r");
    FILE *temp = fopen(tempFile, "w");

    if (!file || !temp) {
        printf("Error opening files.\n");
        return;
    }

    printf("Enter ID to update: "); gets(id);
    printf("Field to update (name/age/major/gpa): "); gets(field);
    printf("Enter new value: "); gets(new_value);

    int found = 0;
    while (fgets(line, sizeof(line), file)) {
        char record[5][50];
        char *token = strtok(line, "|\n");
        int i = 0;

        while (token && i < 5) {
            strcpy(record[i++], token);
            token = strtok(NULL, "|\n");
        }

        if (strcmp(record[0], id) == 0) {
            found = 1;
            if (strcmp(field, "name") == 0) strcpy(record[1], new_value);
            else if (strcmp(field, "age") == 0) strcpy(record[2], new_value);
            else if (strcmp(field, "major") == 0) strcpy(record[3], new_value);
            else if (strcmp(field, "gpa") == 0) strcpy(record[4], new_value);
            else printf("Invalid field.\n");
        }

        fprintf(temp, "%s|%s|%s|%s|%s\n", record[0], record[1], record[2], record[3], record[4]);
    }

    fclose(file);
    fclose(temp);

    remove(FILENAME);
    rename(tempFile, FILENAME);

    if (found)
        printf("Record updated successfully.\n\n");
    else
        printf("Record not found.\n\n");
}

// ---------- DELETE ----------
void delete_student() {
    char id[20], line[200];
    char tempFile[] = "temp.txt";
    FILE *file = fopen(FILENAME, "r");
    FILE *temp = fopen(tempFile, "w");

    if (!file || !temp) {
        printf("Error opening files.\n");
        return;
    }

    printf("Enter ID to delete: "); gets(id);

    int found = 0;
    while (fgets(line, sizeof(line), file)) {
        char record_id[20];
        sscanf(line, "%[^|]", record_id);

        if (strcmp(record_id, id) != 0) {
            fputs(line, temp);
        } else {
            found = 1;
        }
    }

    fclose(file);
    fclose(temp);

    remove(FILENAME);
    rename(tempFile, FILENAME);

    if (found)
        printf("Record deleted successfully.\n\n");
    else
        printf("Record not found.\n\n");
}

// ---------- MENU ----------
void menu() {
    while (1) {
        printf("========== Student Database Menu ==========\n");
        printf("1. Insert Student\n");
        printf("2. View All Students\n");
        printf("3. Update Student\n");
        printf("4. Delete Student\n");
        printf("5. Exit\n");
        printf("Enter your choice: ");

        char choice[5];
        gets(choice);

        if (strcmp(choice, "1") == 0) insert_student();
        else if (strcmp(choice, "2") == 0) read_students();
        else if (strcmp(choice, "3") == 0) update_student();
        else if (strcmp(choice, "4") == 0) delete_student();
        else if (strcmp(choice, "5") == 0) {
            printf("Exiting program.\n");
            break;
        } else {
            printf("Invalid choice.\n\n");
        }
    }
}

// ---------- MAIN ----------
int main() {
    menu();
    return 0;
}
