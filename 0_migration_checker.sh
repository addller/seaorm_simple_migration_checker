#!/usr/bin/env bash

if ! which awk > /dev/null 2>&1; then
    echo "awk is not installed, please install it to run this script"
    exit 1
fi

#Base directory for entities
ENTITIES_DIR="./src/api/entities"
ENTITIES_DIR_FOUND=false

#Rust sea orm migration checker started.
echo "Starting rust sea orm Simple Migration Checker..."

if [ ! -d "$ENTITIES_DIR" ]; then
  echo "Directory $ENTITIES_DIR does not exist."
  echo -e "Searching for entities directory...\n"
  ENTITIES_DIR=$(find . -name "entities" -type d)
    if [ -z "$ENTITIES_DIR" ]; then
        echo "Could not find the entities directory."
        exit 1
    else
        for dir in $ENTITIES_DIR; do
            read -p "Found entities directory at: $dir, continue: y/n? " RESPONSE
            if [[ "$RESPONSE" == "y" ]] || [[ "$RESPONSE" == "Y" ]]; then
                ENTITIES_DIR_FOUND=true
                ENTITIES_DIR="$dir"
                break
            fi
        done
    fi
else
    ENTITIES_DIR_FOUND=true
fi

if [ "$ENTITIES_DIR_FOUND" = false ]; then
    echo "No entities directory selected, exiting."
    exit 1
fi

#função para verificar os atributos declarados em uma struct rust
check_struct_attributes() {
    local FILE_ENTITY_PATH="$1"
    local ENTITY_TYPE=""
    local START_IDENTIFICATION_FIELDS=false
    local END_IDENTIFICATION_FIELDS=false
    local STRUCT_NAME=""
    local FIELDS=()
    # Use grep to find lines that match the pattern of struct definitions
    while read -r line; do
        #identify Entity type;
        if grep -qE 'type\s+\w+\s*=\s*\w+' <<< "$line"; then
            local modifier=$(echo "$line" | awk '{print $1}')
            if [ "$modifier" != "pub" ]; then
                echo "Entity type definition is not public: $line"
                exit 1
            fi
            ENTITY_TYPE=$(echo "$line" | awk '{print $3}')
            continue
        fi

        #identify struct Model
        if grep -qE 'struct\s+\w+' <<< "$line"; then
            STRUCT_NAME=$(echo "$line" | awk '{print $3}')
        fi

        if grep -qE '{' <<< "$line" && [ -n "$STRUCT_NAME" ]; then
            START_IDENTIFICATION_FIELDS=true
            continue
        fi

        if grep -qE '}' <<< "$line" && [ "$START_IDENTIFICATION_FIELDS" = true ]; then
            END_IDENTIFICATION_FIELDS=true
            break
        fi

        #remove all spaces and tabs from the line
        local line_no_spaces=$(echo "$line" | tr -d '[:space:]')
        
        #remove macro applications
        if grep -qE '#\[\w+' <<< "$line_no_spaces"; then
            continue
        fi

        #remove single line comments
        if grep -qE '^//' <<< "$line_no_spaces"; then
            continue
        fi
        

        if [[ -n "$line_no_spaces" ]] && [[ "$START_IDENTIFICATION_FIELDS" = true ]]; then
     
            #field must be public
            if ! grep -qE 'pub\s+\w+' <<< "$line"; then
                echo "Field is not public: $line"
                echo "File: $FILE_ENTITY_PATH"
                exit 1
            fi
            local FIELD=$(echo "$line" | awk '{print $2}' | tr -d ';'| tr -d ':')
            FIELDS+=("$FIELD")
        fi


    done < "$FILE_ENTITY_PATH"

    if [[ -z "$ENTITY_TYPE" ]]; then
        echo "Could not identify the entity type in $FILE_ENTITY_PATH"
        exit 1
    fi
    
    if [[ "$END_IDENTIFICATION_FIELDS" = false ]]; then
        echo "Could not identify the end of the struct fields in $FILE_ENTITY_PATH"
        exit 1
    fi

    compare_entity_atributes_with_migrations "$ENTITY_TYPE" "$FILE_ENTITY_PATH" FIELDS[@]
}

compare_entity_atributes_with_migrations(){
    MIGRATION_FILE_PATHS=$(find ./migration/ -name "m*_*_*\.rs")
    local ENTITY_FIELDS=("${!3}")
    local ENTITY_FIELDS_APPLYED=("${!3}")

    for file in $MIGRATION_FILE_PATHS; do
        local FOUNDED_ENTITY_FIELDS=()

        local ENTITY_NAME="$1"
        local ENTITY_FOUNDS_IN_MIGRATION=false
        local START_IDENTIFICATION_FIELDS=false

        while read -r line; do
            if grep -qE "enum $ENTITY_NAME\s*{" <<< "$line" ; then
                ENTITY_FOUNDS_IN_MIGRATION=true
                
                if grep -qE "}" <<< "$line"; then
                    break
                fi
                
                continue
            fi

            if [[ "$ENTITY_FOUNDS_IN_MIGRATION" = true ]]; then
                if grep -qE '}' <<< "$line"; then
                    break
                fi

                #get field name from line
                local MIGRATION_FIELD=$(echo "$line" | awk '{print $1}' | tr -d ',')

                #remove finded field from ENTITY_FIELDS array
                for i in "${!ENTITY_FIELDS[@]}"; do
                    UPPERCASE_ENTITY_FIELD=$(apply_upper_migration_entity_uppercase "${ENTITY_FIELDS[i]}")

                    if [[ "${UPPERCASE_ENTITY_FIELD}" == "$MIGRATION_FIELD" ]]; then
                        unset 'ENTITY_FIELDS[i]'
                        FOUNDED_ENTITY_FIELDS+=("${ENTITY_FIELDS_APPLYED[i]}")
                    fi
                done
            fi

        done < "$file"
        verify_application_of_founded_fields "$ENTITY_NAME" "$file" FOUNDED_ENTITY_FIELDS[@]
    done

    if [[ ${#ENTITY_FIELDS[@]} -gt 0 ]]; then
        echo "The following fields of $ENTITY_NAME entity were not found in any migration files:"
        for field in "${ENTITY_FIELDS[@]}"; do
            echo "- $field"
        done
        echo "Entity file path: $2"
        exit 1
    fi

}

apply_upper_migration_entity_uppercase(){
    local FIELD_NAME="$1"
    local FIELD_NAME_UPPERCASE=$(echo "$FIELD_NAME" | sed -E 's/(_)([a-z])/\U\2/g' | sed -E 's/^([a-z])/\U\1/')
    echo "$FIELD_NAME_UPPERCASE"
}

verify_application_of_founded_fields(){
    local ENTITY_NAME="$1"
    local MIGRATION_FILE_PATH="$2"
    local FOUNDED_ENTITY_FIELDS=("${!3}")
    local FILE_CONTENT=$(cat "$MIGRATION_FILE_PATH")
    
    for field in "${FOUNDED_ENTITY_FIELDS[@]}"; do
            UPPERCASE_ENTITY_FIELD=$(apply_upper_migration_entity_uppercase "$field")

            if grep -qE "${ENTITY_NAME}::${UPPERCASE_ENTITY_FIELD}" <<< "$FILE_CONTENT"; then
                #remove finded field from FOUNDED_ENTITY_FIELDS array
                for i in "${!FOUNDED_ENTITY_FIELDS[@]}"; do
                    if [[ "${FOUNDED_ENTITY_FIELDS[i]}" == "$field" ]]; then
                        unset 'FOUNDED_ENTITY_FIELDS[i]'
                    fi
                done
            fi
    done

    if [[ ${#FOUNDED_ENTITY_FIELDS[@]} -gt 0 ]]; then
        echo "The following declared fields of $ENTITY_NAME entity apparently were not applied in the migration file $MIGRATION_FILE_PATH:"
        for field in "${FOUNDED_ENTITY_FIELDS[@]}"; do
            echo "- $field"
        done
        exit 1
    fi
}

ENTITIES_FILES=$(ls -1 "$ENTITIES_DIR" | grep -E '.rs$' | sed "s|^|$ENTITIES_DIR/|")

for file in $ENTITIES_FILES; do
    check_struct_attributes "$file"
done

echo "All entity files passed the check."
echo "We apply a simple check to verification on all migration files, we can not guarantee a full consistency check because one column can be applied on one migration and updated in another migration, but we only consider the first migration that apply the column"
echo "Rust sea orm migration checker finished successfully."