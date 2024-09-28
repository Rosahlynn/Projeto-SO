#!/bin/bash

# Arquivo de saída para resultados
output_file="journalctl_logrotate_test_results.csv"

# Cabeçalho da tabela de resultados no CSV
echo "Comando, Repetição, Tempo de Execução (s), Leitura no Disco (KB), Escrita no Disco (KB), Troca de Contexto Antes, Troca de Contexto Depois" > $output_file

# Função para executar o teste de desempenho
run_test() {
    command="$1"
    repetitions="$2"

    for i in $(seq 1 $repetitions); do
        echo "Executando: $command (Repetição $i)"
        
        # Usa 'strace' para capturar métricas de I/O e troca de contexto e '/usr/bin/time' para o tempo de execução
        # Saída redirecionada para /dev/null para evitar poluição do terminal
        /usr/bin/time -f "%e" strace -c $command > /dev/null 2> temp_output

        # Extrai o tempo de execução
        exec_time=$(grep -oP '\d+\.\d+' <<< $(head -n 1 temp_output))

        # Extrai leitura e escrita no disco
        read_kb=$(grep "read" temp_output | awk '{print $2}')
        write_kb=$(grep "write" temp_output | awk '{print $2}')

        # Extrai troca de contexto antes e depois
        ctx_before=$(grep "voluntary" temp_output | awk '{print $1}')
        ctx_after=$(grep "involuntary" temp_output | awk '{print $1}')
        
        # Armazena os resultados no arquivo CSV
        echo "$command, $i, $exec_time, $read_kb, $write_kb, $ctx_before, $ctx_after" >> $output_file
    done
}

# Número de repetições para cada comando
repetitions=5

# Lista dos comandos a serem testados
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
    run_test "$cmd" $repetitions
done

# Limpeza do arquivo temporário
rm temp_output

echo "Testes concluídos. Resultados armazenados em $output_file."

