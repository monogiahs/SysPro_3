#!/bin/bash

#############################################################################################
#											    #
#					Argument Parser					    #
#											    #
#############################################################################################

if [ "$#" -ne 4 ] 2>/dev/null; then	#number of arguments must be 4.
    echo "Illegal number of parameters."
    exit
elif [ ! -d $1 ]; then	#second argument must be a valid directory.
    echo "$1 does not exist or it's not a valid directory"
    exit
elif [ ! -f $2 ]; then	#third argument must be a valid file.
    echo "$2 does not exist or it's not a valid file"
    exit
fi

NUMOFLINES=$(wc -l < "$2")	    	#use with redirection to get only the number of lines
					#and not the file name, for argument parser
if [ "$NUMOFLINES" -lt 10000 ]; then	#number of lines must be at least 10.000.
    echo "file $2 has less than 10.000 lines"
    exit
fi

if [ $3 -eq $3 ] 2>/dev/null && [ $3 -gt 0 ] 2>/dev/null; then
:					#web site number must be integer, greater than zero.
else
echo "$3 is not a valid parameter"
exit
fi

if [ $4 -eq $4 ] 2>/dev/null && [ $4 -gt 0 ] 2>/dev/null; then
:					#page number must be integer, greater than zero.
else
echo "$4 is not a valid parameter"
exit
fi

if [ -d "$1/site0" ]; then		#if site0 exists in root_directory, its contents
  echo '#' Warning: directory is full, purging ...
  rm -r $1/site*			#must be removed
fi

#############################################################################################


#############################################################################################
#											    #
#					?????????					    #
#											    #
#############################################################################################

for ((w=0; w<"$3"; w++)) do
    for ((p=0; p<"$4"; p++)) do
	unique_random[$p]=$RANDOM	#create random numbers for site name usage
	for ((i=0; i<"$p"; i++)) do
	    if [ "${unique_random[$p]}" == "${unique_random[$i]}" ] ; then
		unset 'unique_random[$p]'
		p=$[$p - 1]		#random numbers must also be unique
		break
	    fi;
	done
    done
    for ((p=0; p<"$4"; p++)) do
	eval "website_array_$w[$p]=$1/site$w/page$w'_'${unique_random[$p]}.html"
    done				#create an array of names of each website pages
done

all_links=()

for ((w=0; w<"$3"; w++)) do
    echo '#' Creating web site $w ...
    mkdir -p $1/site$w			#create w number directories

    declare -n intlinks_temp=website_array_$w
    for ((p=0; p<"$4"; p++)) do		#for each page,

	f=$[$4/2 + 1]			#number of random internal links
	q=$[$3/2 + 1]			#number of random external links
	m=$[$RANDOM%999 + 1001]		#generate a random number 1000 < m < 2000
	k=$[$RANDOM%(NUMOFLINES-2002)+2]
					#generate a random number 1 < k < (lines in text_file-2000)
	nol=$[$m/($f+$q)]		#number of lines to be copied from source file to
					#output file for each link
	sum_nol=$[($nol*($f + $q))+($f + $q)]

	i=0
	break_flag=0
	while [[ "$i" -lt "$f" ]] ; do	#generate f number random internal links
	    intlinks[$i]=${intlinks_temp[$RANDOM % ${#intlinks_temp[@]}]}
	    if [ "${intlinks[$i]}" == "${intlinks_temp[$p]}" ] ; then
		unset 'intlinks[$i]'	#internal links to the same page must not be included
		continue
	    fi;
	    for ((temp_p=0; temp_p<"$i"; temp_p++)) do
		if [ "${intlinks[$i]}" == "${intlinks[$temp_p]}" ] ; then
		    unset 'intlinks[$i]'
		    break_flag=1	#duped internal links must not be included
		    break
		fi;
	    done
	    if [ "$break_flag" == 1 ] ; then
		break_flag=0
		continue
	    fi;
	    ((i++))
	done

	i=0
	break_flag=0
	while [[ "$i" -lt "$q" ]] ; do	#generate q number random external links
	    w_ext=$[$RANDOM % $3]	#select a random website
	    if [ $w_ext -eq $w ] ; then
		continue		#must be different than the one we are working with now
	    fi;
	    declare -n extlinks_temp=website_array_$w_ext
	    extlinks[$i]=${extlinks_temp[$RANDOM % ${#extlinks_temp[@]}]}
					#select a random webpage from the random website
	    for ((temp_q=0; temp_q<"$i"; temp_q++)) do
		if [ "${extlinks[$i]}" == "${extlinks[$temp_q]}" ] ; then
		    unset 'extlinks[$i]'
		    break_flag=1	#duped external links must not be included
		    break
		fi;
	    done
	    if [ "$break_flag" == 1 ] ; then
		break_flag=0
		continue
	    fi;
	    ((i++))
	done

	FILE=${intlinks_temp[$p]}
	echo -e '#''\t'Creating page $FILE with "$sum_nol" lines starting at line "$k" ...

	touch $FILE
	printf "<!DOCTYPE html><html><body><pre>" >> $FILE

	f_temp_i=0
	q_temp_i=0
	break_flag=0
	while [[ "$f_temp_i" -lt "$f" ]] || [[ "$q_temp_i" -lt "$q" ]]; do

	    if [ "$f_temp_i" -lt "$f" ] ; then
		if [ $[$RANDOM%2] -eq 0 ] ; then		#internal links only
		    f_temp=$[$RANDOM%$f]			#random internal link
		    previous_f[f_temp_i]=$f_temp
		    for((i=0; i<$f_temp_i; i++)) do		#check for previously used internal links
			if [ $f_temp == "${previous_f[i]}" ] ; then
			    unset 'previous_f[$f_temp_i]'
			    break_flag=1
			    break
			fi;
		    done
		    if [ "$break_flag" == 1 ] ; then
			break_flag=0
			continue
		    fi;
		    ((f_temp_i++))
		    sed -n $k,$[$k+$nol]'p' $2 >> $FILE		#select lines from input file and write to html
		    echo -e '#''\t'Adding link to "${intlinks[$f_temp]}"
		    echo "<a href='"${intlinks[$f_temp]}"'>"${intlinks[$f_temp]}"_text</a>" >> $FILE
								#write the random link to html
		    k=$[$k+$nol+1]				#next writing must begin from line k
		    all_links+=("${intlinks[$f_temp]}")		#append to array for incoming links usage
		fi;
	    fi;

	    if [ "$q_temp_i" -lt "$q" ] ; then
		if [ $[$RANDOM%2] -eq 1 ] ; then		#external links only
		    q_temp=$[$RANDOM%$q]			#random external link
		    previous_q[q_temp_i]=$q_temp
		    for((i=0; i<$q_temp_i; i++)) do		#check for previously used external links
			if [ $q_temp == "${previous_q[i]}" ] ; then
			    unset 'previous_q[$q_temp_i]'
			    break_flag=1
			    break
			fi;
		    done
		    if [ "$break_flag" == 1 ] ; then
			break_flag=0
			continue
		    fi;
		    ((q_temp_i++))
		    sed -n $k,$[$k+$nol]'p' $2 >> $FILE		#select lines from input file and write to html
		    echo -e '#''\t'Adding link to "${extlinks[$q_temp]}"
		    echo "<a href='"${extlinks[$q_temp]}"'>"${extlinks[$q_temp]}"_text</a>" >> $FILE
								#write the random link to html
		    k=$[$k+$nol+1]				#next writing must begin from line k
		    all_links+=("${extlinks[$q_temp]}")		#append to array for incoming links usage
		fi;
	    fi;

	done
	printf "</pre></body></html>" >> $FILE
    done
done

found=0
for ((w=0; w<"$3"; w++)) do
    declare -n links_temp=website_array_$w
    for ((p=0; p<"$4"; p++)) do
	for links in ${all_links[@]}; do
	    if [ "$links" == "${links_temp[$p]}" ] ; then
		((found++))	#if specific webpage has incoming link
		break;
	    fi;
	done
    done
done


if [ "$found" == "$[$w*$p]" ] ; then
    echo '#' All pages have at least one incoming link
else
	echo Some pages do not have incoming links
fi;
echo '#' Done.

#	firefox $FILE




