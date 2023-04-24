# Генерация симметричного ключа


function message_encoder() {
    local mes=$1
    local path=$2
    echo "$mes" | openssl enc -aes-256-cbc -salt -pass file:tmp/key.txt -out $path 2> /dev/null)
}

function message_decoder() {
    local encoded_mes=$1
    local path=$2
    openssl enc -d -aes-256-cbc -salt -pass file:tmp/key.txt -in $path 2> /dev/null)
}

message_encoder 