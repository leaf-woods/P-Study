#!/bin/bash

### -a 王维
M_A="-a";
### -al all authors
M_ALL="-al";
### -t all types
M_T="-t";
### -ti title
M_TI="-ti";

### TODO: query by title; query by sentences


author="";
row="";
title="";
typeid="";

# PO, LY, QU, AR
types=(0, 0, 0, 0);

print_header() {
    date;
    echo "P-Study: Simple Report Utility";
    echo "Prerequites: exppoems.csv and types.csv are under same directory where this program locates.";
    echo;
}

get_types() {
    if [ $typeid -lt 11 ] 
    then 
        types[0]=$((${types[0]}+1));

    else
        if [ $typeid -lt 24 ] 
        then
            types[1]=$((${types[1]}+1));

        else
            if [ $typeid -lt 27 ] 
            then
                types[2]=$((${types[2]}+1));
            else
                types[3]=$((${types[3]}+1));
            fi    
        fi
    fi

}

print_types() {
    date;
    echo "Items in different types";
    echo "Poems   : ${types[0]}";
    echo "Lyrics  : ${types[1]}";
    echo "Qu      : ${types[2]}";
    echo "Articles: ${types[3]}";
}

### -t all types
### has to present first
if [ "$#" == 0 ] || [ $1 == $M_T ]
then
    echo "Getting data for all types";
    while IFS= read -r line; 
    do
        typeid=$(echo $line | awk -F";" '{print $4}');
        get_types;
 
    done < exppoems.csv
    print_types;
    exit;
fi

### -a 王维
if [ $1 == $M_A ] 
then
    author=$2;
    if [ ${#author}  == 0 ]
    then
        echo "Missing author name.";
        exit;
    fi
    echo "Getting data for $2";
    result=$(awk -v var="$author" '$0 ~ var {print}' exppoems.csv | awk -F";" '{print $1";"$2}');
    awk -F";" '{print}' <<< $result;
    ct=$(wc -l <<< $result);
    echo "Total: $ct";
    exit;
fi

### -al all authors
if [ $1 == $M_ALL ] 
then
    echo "Getting data for all authors";
    result=$(awk -F";" '{print $3}' exppoems.csv | sort | uniq -c | awk '{print $2";"$1}');
    awk -F";" '{print}' <<< $result;
    ct=$(wc -l <<< $result);
    echo "Total authors: $ct";
    exit;
fi

### -ti title
if [ $1 == $M_TI ] 
then
    title=$2;
    if [ ${#title}  == 0 ]
    then
        echo "Missing title.";
        exit;
    fi
    echo "Getting data for $2";
    result=$(awk -v var="$title" '$0 ~ var {print}' exppoems.csv | awk -F";" '{print $1";"$3";"$2}');
    awk -F";" '{print}' <<< $result;
    ct=$(wc -l <<< $result);
    echo "Total: $ct";
    exit;
fi
