#!/bin/bash

#sudo apt update && sudo apt install docker docker-compose
echo "  Для продолжения требуется docker и docker-compose"
echo "  для установки используйте"
echo -e "sudo apt update && sudo apt install docker docker-compose\n"

default_file_name="docker-compose-shadowsocks.yml"
json_config_file_name="shadowsocks.json"

echo -e "  В текущей папке будут созданы 2 файла:\n$default_file_name\n$json_config_file_name\n  убедитесь, что их нет в текущей папке"

create_docker_compose_yml() {
    if [ ! -e $default_file_name ] && [ ! -e $json_config_file_name ]; then
        use_port=8388
        echo -n "Введите PORT или будет использован $use_port: "
        read use_port_input

        if [ -n "$use_port_input" ]; then
            use_port=$use_port_input
        fi

        echo -n "Введите ПАРОЛЬ или он будет сгенерирован: "
        read pass_input

        if [ -n "$pass_input" ]; then
            pass=$pass_input
        else
            echo "Создаем пароль"
            choose() { echo ${1:RANDOM%${#1}:1} $RANDOM; }
            pass="$({ choose '!@#$'
              choose '0123456789'
              choose 'abcdefghijklmnopqrstuvwxyz'
              choose 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
              for i in $( seq 1 $(( 4 + RANDOM % 8 )) )
                 do
                    choose '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
                 done
            } | sort -R | awk '{printf "%s",$1}')"
            echo "Пароль: $pass"
        fi

        my_ip=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')

        echo "Подтведите IP сервера: $my_ip"
        select yn in "ДА" "НЕТ" 
        do
            case $yn in
                ДА )
                break
                ;;
                НЕТ )
                read -p "Введите IP: " my_ip
                break
                ;;
                *) echo "Нет такого выбора $REPLY";;
            esac
        done

        docker_file_yml=\
"shadowsocks:
  image: shadowsocks/shadowsocks-libev
  container_name: shadowsocks_tutty_script_container
  ports:
    - "$use_port:8388/udp"
    - "$use_port:8388/tcp"
  environment:
    - METHOD=aes-256-gcm
    - PASSWORD=$pass
  restart: always"
        
        touch $default_file_name
        if [ -e $default_file_name ]; then
            echo "$docker_file_yml" >> $default_file_name
            if [ -s $default_file_name ]; then
                echo "$default_file_name успешно создан в текущей папке, используйте скрипт №2 для запуска контейнера или используйте docker-compose"
            else
                echo "ОШИБКА сохранения, проверьте права на запись в текущей папке"
            fi
        fi

        shadowsocks_config=\
"{
    "server":"$my_ip",
    "server_port":"$use_port",
    "local_address": "127.0.0.1",
    "local_port":1080,
    "password":"$pass",
    "timeout":300,
    "method":"aes-256-gcm",
    "fast_open": false
}"

        if [ ! -e $json_config_file_name ]; then
            touch $json_config_file_name
            if [ -e $json_config_file_name ]; then
                echo "$shadowsocks_config" >> $json_config_file_name
                if [ -s $json_config_file_name ]; then
                    echo "$json_config_file_name успешно создан в текущей папке, используйте его для подключения клиента"
                else
                    echo "ОШИБКА сохранения, проверьте права на запись в текущей папке"
                fi
            fi
        fi
    else
        if [ -e $default_file_name ]; then
            echo "ОШИБКА - файл $default_file_name уже есть в текущей папке, удалите его или перенесите файл скрипта в другую папку"
        fi
        if [ -e $json_config_file_name ]; then
            echo "ОШИБКА - файл $json_config_file_name уже есть в текущей папке, удалите его или перенесите файл скрипта в другую папку"
        fi
    fi
}

start_container() {
    docker-compose -f $default_file_name up -d
}

echo "Выберите вариант для продолжения:"

functions=(
    "Создать $default_file_name + конфиг"
    "Запустить контейнер из $default_file_name"
    "Выход"
)

select opt in "${functions[@]}"
do
   case $opt in
       "${functions[0]}")
            create_docker_compose_yml
            break
            # start_container
            ;;
       "${functions[1]}")
            start_container
            break
            ;;
       "Выход")
            break
            ;;
       *) echo "Нет такого выбора $REPLY";;
   esac
done