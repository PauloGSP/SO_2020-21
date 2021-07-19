#!/bin/bash
#Paulo Pereira 98430   (50%)
#Alexandre Serras 97505 (50%)
if (( $# == 0));then
	echo "Precisa de argumentos"
	exit
fi
declare -A temp_r=() # array dinamico temporario para verificar os processos
declare -A temp_w=() # array dinamico temporario para verificar os processos
declare -A arrayOpt=()  #cria um array dinamico que vai permitir guardar todas as opcoes
cabecalho="%-15s %-13s %8s %11s %11s %11s %11s %13s %13s %13s "
formatacao="%-15s %-13s %8s %11s %11s %11s %11s %13s %13s %3s %3s %5s \n"


cd /proc/

for ultimo_arg; do true; done
	segundos=$ultimo_arg
	if (( $segundos <= 0   ));then
		printf "Os segundos tem de ser números positivos\n"
		exit
	fi
printf "$cabecalho" "COMM" "USER" "PID" "MEM" "RSS" "READB" "WRITEB" "RATER" "RATEW" "DATE"	
pid=$(ps -ef  | grep 'p' | awk '{print $2}')


for processos in $pid ;do
	if [ -d  $processos ];then
		cd ./$processos
		if [ -r ./io ];then
			rchar=$(cat /proc/$processos/io | grep rchar |   grep -o -E '[0-9]+'  )
			wchar=$(cat /proc/$processos/io | grep wchar |  grep -o -E '[0-9]+'  )
            temp_r[$processos]=$rchar 
            temp_w[$processos]=$wchar 
		fi
		cd ../
	fi
done

process_values=()
index=0
contador=0
sleep $segundos

for processos in $pid; do
    if [[ ${temp_r[$processos]} ]];then
        if [ -d  $processos ];then
            cd ./$processos
                if [ -r ./io ];then
                    var1=${temp_w[$processos]} 
                    var2=${temp_r[$processos]} 
                    comm=$(cat /proc/$processos/comm )
                    comm="${comm// /_}"
                    rchar=$(cat /proc/$processos/io | grep rchar |   grep -o -E '[0-9]+'  )
                    wchar=$(cat /proc/$processos/io | grep wchar |  grep -o -E '[0-9]+'  )
                    rbyte=$(cat /proc/$processos/io | grep read_byte |   grep -o -E '[0-9]+'  )
                    writebyte=$(cat /proc/$processos/io | grep write_byte |  grep -o -E '[0-9]+'    )
                    contador=0;
                    for wb in $writebyte ;do
                        if (( contador == 0 ));then
                            wbyte=$wb
                            break
                        fi
                    done
                    ratert="$(($rchar-$var2))"
                    rater=`echo "scale=2;$ratert/$segundos" | bc`  
                    raterw="$(($wchar-$var1))"
                    ratew=`echo "scale=2;$raterw/$segundos" | bc` 
                    VmSize=$(cat /proc/$processos/status | grep VmSize | grep -o -E '[0-9]+'  )
                    VmRss=$(cat /proc/$processos/status | grep VmRSS |  grep -o -E '[0-9]+'   )
                    data=$(LC_ALL=EN_us.utf8 ls -ld /proc/$processos | awk '{print $6 " " $7 " " $8}')
                    compare_num=$(date -d "$data" +%s)
                    utilizador=$(ls -ld /proc/$processos | awk '{print $3}')
                    process_values[$index]="$comm $utilizador $processos $VmSize $VmRss $rbyte $wbyte $rater $ratew $data $compare_num "
                    index=$((index+1))
                fi
                cd ../
        fi 
    fi
done

if [[ -n $pid ]]; then
	echo ""
else
	echo "Não existe nenhum "
fi	
    
controlo=0
controlo_args=0
while getopts ":wrdtmp:u:e:s:c:" opt; do
	controlo_args=$((controlo_args+1))
	vars=$#
	case $opt in
		m|t|d|w)
			if (( $controlo == 1)) ;then
				echo "Error: Apenas se pode colocar um destes 4 argumentos: m,t,d,w"
				exit
			fi
			controlo=$((controlo+1))
			;;
		p)
			controlo_args=$((controlo_args+1))
			if (( $controlo_args >= $((vars))));then
				echo "ERRO: Não se pode usar os segundos como argumento de uma opção"
				exit
			fi
			if (( $OPTARG <= 0   ));then
				echo "Escolher valores positivos"
				exit
			fi
			;;
		u)   
			controlo_args=$((controlo_args+1))
			if (( $controlo_args >= $((vars))));then
				echo "ERRO: Não se pode usar os segundos como argumento de uma opção"
				exit
			fi
		   	
		   	;;
			
		s|e)
			controlo_args=$((controlo_args+1))
			if (( $controlo_args >= $((vars))));then
				echo "ERRO: Não se pode usar os segundos como argumento de uma opção"
				exit
			fi
			
			if [[ $OPTARG =~ *":"* ]];then
				echo "Data Inválida"
				exit
			fi
			OPTARG=$(date -d "$OPTARG" +%s)
			if [[ -z $OPTARG  ]];then	
				exit
			fi
			;;
		c)
			controlo_args=$((controlo_args+1))
			if (( $controlo_args >= $((vars))));then
				echo "ERRO: Não se pode usar os segundos como argumento de uma opção"
				exit
			fi
			;;
		r)
			;;
		\?)
			echo "ERRO: Opção inválida: -$OPTARG"
			exit
			;;
		:)
			echo "ERRO: opção -$OPTARG Precisa de argumentos."
			exit
			;;
		*)
			echo "ERRO: Opção não implementada: -$OPTARG"
			exit
			;;
	esac
	if [[ $OPTARG == "" ]]; then
		arrayOpt[$opt]=" "		# Caso o argumento nao tenha argumento guarda vazio 
	else
		arrayOpt[$opt]=$OPTARG		# Caso o argumento tenha argumento é guardado o valor
	fi
done
shift $((OPTIND - 1))

if [[ ${arrayOpt['c']} ]];then
	validar=${arrayOpt['c']}
	for i in "${!process_values[@]}"; do
		lista=(${process_values[i]})
		comando=${lista[0]}
		if [[ ! $comando =~ $validar ]];then
			unset process_values[i]
			index=$((index - 1))
		fi
	done
fi
if [[ ${arrayOpt['s']} ]];then
	validar=${arrayOpt['s']}
	for i in "${!process_values[@]}"; do
		lista=(${process_values[i]})
		valor=${lista[12]}
		if (( $valor < $validar));then
			unset process_values[i]
			index=$((index - 1))
		fi
	done
fi
if [[ ${arrayOpt['e']} ]];then
	validar=${arrayOpt['e']}
	for i in "${!process_values[@]}"; do
		lista=(${process_values[i]})
		valor=${lista[12]}
		if (( $valor > $validar));then
			unset process_values[i]
			index=$((index - 1))
		fi
	done
fi
if [[ ${arrayOpt['u']} ]];then
	validar=${arrayOpt['u']}
	for i in "${!process_values[@]}"; do
		lista=(${process_values[i]})
		utilizador=${lista[1]}
		if [[ ! $utilizador ==  "$validar" ]];then
			unset process_values[i]
			index=$((index - 1))
		fi
	done
fi

verifica_r="r"		#por default está ordenado com reverse ativo para ficar de ordem decrescente
if [[ ${arrayOpt['r']} ]]; then
	verifica_r=""
fi

if [[ ${arrayOpt['w']} ]]; then
	IFS=$'\n' 
	arrayOrdenado=($(sort -k9,9n$verifica_r <<<"${process_values[*]}"))
	unset IFS
elif [[ ${arrayOpt['d']} ]]; then
	IFS=$'\n' 
	arrayOrdenado=($(sort -k8,8n$verifica_r<<<"${process_values[*]}"))
	unset IFS
elif [[ ${arrayOpt['m']} ]]; then
	IFS=$'\n' 
	arrayOrdenado=($(sort -k4,4n$verifica_r<<<"${process_values[*]}"))
	unset IFS
elif [[ ${arrayOpt['t']} ]]; then
	IFS=$'\n' 
	arrayOrdenado=($(sort -k5,5n$verifica_r<<<"${process_values[*]}"))
	unset IFS
else
	verifica_r=""		#por default está ordenado com reverse ativo para ficar de ordem decrescente
	if [[ ${arrayOpt['r']} ]]; then
		verifica_r="r"
	fi
	IFS=$'\n' 
	arrayOrdenado=($(sort -k1,1$verifica_r<<<"${process_values[*]}"))
	unset IFS
fi 
if [[ ${arrayOpt['p']} ]];then
	maximo=${arrayOpt['p']}
	for ((i=0; i<$maximo; i++ )) ;do
		lista=(${arrayOrdenado[i]})
		printf "$formatacao" ${lista[0]} ${lista[1]} ${lista[2]} ${lista[3]} ${lista[4]} ${lista[5]} ${lista[6]} ${lista[7]} ${lista[8]} ${lista[9]} ${lista[10]} ${lista[11]}
	done
else
	for ((i=0; i<$index; i++ )) ;do
		lista=(${arrayOrdenado[i]})
		printf "$formatacao" ${lista[0]} ${lista[1]} ${lista[2]} ${lista[3]} ${lista[4]} ${lista[5]} ${lista[6]} ${lista[7]} ${lista[8]} ${lista[9]} ${lista[10]} ${lista[11]}
	done
fi
