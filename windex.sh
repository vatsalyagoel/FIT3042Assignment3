#!/bin/bash

if [ -z "$1" ]
	then
			printf "Index file not provided\n"
			exit 1;
fi

if [ -z "$2" ]
	then
			printf "lookup word not provided\n"
			exit 1;
fi

INDEX=$1;
WORD=$2;

if [ -z "$3" ] #directory oprional
	then
		DIR=$PWD
else
	DIR=$3
fi

FP="${DIR}/${INDEX}"

if [ -e "$FP" ]
	then
			printf "Word: "
else
	printf "Invalid path \n"
fi

PATTERN="${WORD}"

printf ""

RESULT=$(grep -E "\b${PATTERN}" "${FP}")

echo $RESULT | tr "," "\n"
