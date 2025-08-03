#!/bin/bash

date;
echo "Get contents based on exppoems.csv.";
echo "Prerequites: exppoems.csv and exppoemsbg5.csv are under same directory where this program locates.";
echo;

# 登鸛雀樓：必須是繁體中文， 必須有作者

URL=" https://zh.wikisource.org/wiki/";
# Traditional Chinese characters
AMBIGUITY="可以指";
FOUND=1;
NOT_FOUND=0;

title="";
author="";
row="";

response="";
received="";
found_records="";
i=0;

found=$NOT_FOUND;

############################
#var='<td style="width:50%;"><b>唐多令</b><br>蘆葉滿汀洲<br><span style="color:var(--color-placeholder,#999999)">作者：</span><a href="/wiki/Author:%E5%8A%89%E9%81%8E" title="Author:劉過">劉過</a>　<span style="color:var(--color-placeholder,#999999)">南宋</span> <p>蘆葉滿汀洲，寒沙帶淺流。二十年重過南樓。柳下繫船猶未穩，能幾日，又中秋。<br> 黃鶴斷磯頭，故人<span style="color: black; border-bottom:1px dotted red; BACKGROUND: linen; cursor: help" title="一作「今在否」">曾到不</span>？舊江山渾是新愁。欲買桂花同載酒，終不<span style="color: black; border-bottom:1px dotted red; BACKGROUND: linen; cursor: help" title="一作「是」">似</span>，少年遊。 </p>';
#var=$(echo $var | sed 's/<[^>]*>//g');

#var="aaa(bbb)ccc";
#var=$(echo $var | sed 's/(/\%28/g');
#var=$(echo $var | sed 's/)/\%29/g');
#echo "clean var: $var";
############################

proc_not_found() {
    echo "Cannot get contents for entry [$title, $author].";
}

proc_result() {
    echo Content: $1;
    i=$((i+1));
    found_records="$found_records $row;$title;$author\n";
}

proc_ambiguity() {
    local rv=$NOT_FOUND;
    set -o noglob;
    IFS=$' \t\r\n';
    uarray=($received);   
    set +o noglob;
    #echo;
    #echo "Number: ${#uarray[@]}";
    for ar in "${uarray[@]}"
    do
        # Remove prefix '/wiki/'
        ar=${ar##*/};
        #echo "Processing: $ar";
        url=$URL$ar;
        echo "Processing hyperlink: get data from Url: $url";

        if [[ $url =~ "(" ]]
        then
            echo "Substitute paranthesis.";
            url=$(echo $url | sed 's/(/\%28/g' | sed 's/)/\%29/g');
            echo "Using url: $url";
        fi
    
        received=$(curl $url 2>&1 | awk '/title=\"Author:/{print}/<div class=\"poem\">/{p=1;next}/<\x2fdiv>/{p=0}p{print}');  
        ### TODO: stderr message
        #echo "received: $received";
        #echo "author: $author";
        length=${#received};
        if [ $length -gt 0 ];
        then
            if [[ $received =~ "$author"  ]]
            then
                #echo "found";
                #received=$(echo $received | awk '/<div class=\"poem\">/{p=1;next}/<\x2fdiv>/{p=0}p{print}');

                received=$(echo $received | sed 's/<[^>]*>//g'); 
                proc_result "$received";
                
                found=$FOUND;
                break;
            fi
        fi
    done
}

while IFS= read -r line; 
do
found=$NOT_FOUND;

title=$(echo $line | awk -F";" '{print $2}');
author=$(echo $line | awk -F";" '{print $3}');
row=$(echo $line | awk -F";" '{print $NR}');

echo;
echo "Row: $row";
echo "Title: $title";
echo "Author: $author";

#if [ $row -gt 10 ];
#then
#    break;
#fi

    received=$(curl $URL$title"_"%28$author%29 2>&1 | awk '/<div class=\"poem\">/{p=1;next}/<\x2fdiv>/{p=0}p{print}' | sed '/<sup/,/<\/sup>/d');
    length=${#received};
    echo "Use title and author to search ...";
    echo "Content length: $length";

    if [ $length -gt 0 ];
    then
        received=$(echo $received | sed 's/<[^>]*>//g');
        proc_result "$received";
        continue
    fi

    # Get title and author in traditional Chinese
    title=$(awk -F";" -v var="$row" 'NR==var{print $2}' exppoemsbg5.csv);
    author=$(awk -F";" -v var="$row" 'NR==var{print $3}' exppoemsbg5.csv);
    echo "Title in traditional Chinese: $title";
    echo "Author in traditional Chinese: $author";

    received=$(curl $URL$title"_"%28$author%29 2>&1 | awk '/<div class=\"poem\">/{p=1;next}/<\x2fdiv>/{p=0}p{print}');
    length=${#received};
    echo "Use traditional Chinese to search...";
    echo "Content length: $length";
    if [ $length -gt 0 ];
    then
        received=$(echo $received | sed 's/<[^>]*>//g');
        proc_result "$received";
        continue
    fi
    
    # Try title only. Still use traditional Chinese.
    echo "Use only title to search...";
    #result=$(curl $URL$title 2>&1 | awk '/<div class=\"poem\">/{p=1;next}/<\x2fdiv>/{p=0}p{print}');
    
    response=$(curl $URL$title 2>&1);

    ### At this moment 20250803, two cases presented
    ### 賣花聲(different author) 
    ### 唐多令(ambiguity)

    check_ambiguity=$(grep "$AMBIGUITY" <<< $response);
    echo "Check ambiguity: $check_ambiguity";

    if [ ${#check_ambiguity} -eq 0 ]
    then
        # Check correctness of the result since author is not used in search.
        check_author=$(grep "Author:$author" <<< $response); # colon?
        echo "Check author: $check_author";
        if [ ${#check_author} -gt 0 ] 
        then
            received=$(echo "$response" | awk '/<div class=\"poem\">/{p=1;next}/<\x2fdiv>/{p=0}p{print}');
            #echo "Received: $received";
            length=${#received};
            echo "Content length: $length";
            if [ $length -gt 0 ];
            then
                received=$(echo $received | sed 's/<[^>]*>//g');
                proc_result "$received"; 
                continue
            fi
        else
            proc_not_found;
        fi
        
    else
        echo "Processing ambiguity";
        received=$(echo "$response" | awk '/可以指/{p=1}/<ul>/{f=1; if(p==1 && f==1) {print}} /<\x2ful>/{f=0; if (p==1 && f==0) {print; exit;}}' | awk -F"\"" '{print $2}');
        #echo "Received: $received";
        proc_ambiguity;
        echo "Found? $found";
        if [ $found == $NOT_FOUND ]
        then
            proc_not_found;
        fi 
    fi



    #test=$(curl https://zh.wikisource.org/wiki/$title 2>&1 | awk '/可以指/{p=1}/<ul>/{f=1; if(p==1 && f==1) {print}} /<\x2ful>/{f=0; if (p==1 && f==0) {print; exit;}}' | awk -F"\"" '{print $2}');
    #echo "test: $test";
    #if [ ${#test} -eq 0 ]
    #then
        ### TODO
    #    echo "Cannot get contents for entry [$title, $author].";
    #    continue;
    #fi

    
done < exppoems.csv
echo;
echo "Records Found: $i";
echo -e $found_records;
