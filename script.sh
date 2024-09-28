#!/bin/bash

# Arquivo de saída para resultados
output_file="test_results.csv"

# Cabeçalho da tabela de resultados
echo "Comando, Repetição, Tempo de Execução (s), Leitura no Disco (KB), Escrita no Disco (KB), Troca de Contexto Antes, Troca de Contexto Depois" > $output_file

# Função para executar o teste de desempenho
run_test() {
    command="$1"
    repetitions="$2"

    for i in $(seq 1 $repetitions); do
        # Executa o comando e coleta dados com time, strace e vmstat
        /usr/bin/time -v strace -c $command > /dev/null 2> temp_output
        # Captura os dados de interesse
        exec_time=$(grep "Elapsed" temp_output | awk '{print $8}')
        read_kb=$(grep "read" temp_output | awk '{print $2}')
        write_kb=$(grep "write" temp_output | awk '{print $2}')
        ctx_before=$(grep "voluntary" temp_output | awk '{print $1}')
        ctx_after=$(grep "involuntary" temp_output | awk '{print $1}')
        
        # Escreve os resultados no arquivo CSV
        echo "$command, $i, $exec_time, $read_kb, $write_kb, $ctx_before, $ctx_after" >> $output_file
    done
}

# Número de repetições para cada comando
reps=5

# Comandos para testar
commands=(
    "journalctl"
    "journalctl -b"
    "journalctl --since '2023-09-19 10:00:00'"
    "journalctl -u ssh.service"
    "journalctl -f"
    "journalctl --disk-usage"
    "journalctl --vacuum-size=100M"
    "logrotate -f /etc/logrotate.d/apache2"
)

# Executa os testes para cada comando
for cmd in "${commands[@]}"; do
    run_test "$cmd" $reps
done

# Limpeza de arquivos temporários
rm temp_output
