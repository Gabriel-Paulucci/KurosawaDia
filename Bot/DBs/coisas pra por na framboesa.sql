insert into Tipos_Cargos values (2, "Cargos por XP (XpRole)");
alter table Cargos add column requesito bigint not null default 0;
create table PontosInterativos (
	cod bigint not null auto_increment,
    servidores_usuarios_servidor int not null,
    servidores_usuarios_usuario int not null,
    PI bigint not null default 1,
    fragmentosPI bigint not null default 0,
    foreign key (servidores_usuarios_servidor, servidores_usuarios_usuario) references servidores_usuarios(Servidores_codigo_servidor, Usuarios_codigo_usuario),
    primary key (cod)
);

create table ConfiguracoesServidores(
	cod bigint not null auto_increment,
    cod_servidor int not null,
    idioma int not null default 0,
    PIConf bool not null default false,
    PIrate double not null default 2.0,
    msgError bool not null default true,
    DiaAPI bool not null default true,
    MsgPIUp text,
    bemvindoMsg text,
    sairMsg text,
    foreign key (cod_servidor) references Servidores (codigo_servidor),
    primary key (cod)
);

delimiter $$
create function verificarConfig(
		_codServidor int
) returns int begin
	declare _return int;
    set _return = (select count(cod) from configuracoesservidores where cod_servidor = _codServidor);
    return _return;
end$$

create procedure criarConfig(
	in _codServidor int
) begin
	if((select verificarConfig(_codServidor)) = 0) then
		insert into configuracoesservidores (cod_servidor) values (_codServidor);
	end if;
end$$

create procedure configurePI(
	in _idServidor bigint,
    in _piconf bool,
    in _pirate double,
    in _msgPiup text
) begin
	declare _cod int;
    set _cod = (select codigo_servidor from Servidores where id_servidor = _idServidor);
    call criarConfig(_cod);
    update configuracoesservidores set PIConf = _piconf where cod_servidor = _cod;
    update configuracoesservidores set PIrate = _pirate where cod_servidor = _cod;
    if (_msgPiup <> "") then
		update configuracoesservidores set MsgPIUp = _msgPiup where cod_servidor = _cod;
	else
		update configuracoesservidores set MsgPIUp = NULL where cod_servidor = _cod;
	end if;
end$$


create function verificarPI(
	_codServidor int,
    _codUsuario int
) returns int begin
	declare _return int;
    set _return = (select count(cod) from pontosinterativos where servidores_usuarios_servidor = _codServidor and servidores_usuarios_usuario = _codUsuario);
    return _return;
end$$

create procedure CriarPI(
	in _codServidor int,
	in _codUsuario int
) begin
	if((select verificarPI(_codServidor, _codUsuario)) = 0) then
		insert into pontosinterativos (servidores_usuarios_servidor, servidores_usuarios_usuario) values (_codServidor, _codUsuario);
	end if;
end$$
	
    
create procedure LevelUP(
	in _codServidor int,
    in _codUsuario int
)begin
	declare _multi double;
    declare _fragmento bigint;
    declare _levelAtual int;
    set _multi = (select PIrate from configuracoesservidores where cod_servidor = _codServidor);
    set _fragmento = (select fragmentosPI from pontosinterativos where servidores_usuarios_servidor = _codServidor and servidores_usuarios_usuario = _codUsuario);
    set _levelAtual = (select pontosinterativos.PI from pontosinterativos where servidores_usuarios_servidor = _codServidor and servidores_usuarios_usuario = _codUsuario);
    if(_fragmento >= (_levelAtual * (_multi * 10))) then
		update pontosinterativos set pontosinterativos.PI = (pontosinterativos.PI + 1), fragmentosPI = 0 where servidores_usuarios_servidor = _codServidor and servidores_usuarios_usuario = _codUsuario;
        
        select true as Upou, _levelAtual as LevelAtual, MsgPIUp from configuracoesservidores where cod_servidor = _codServidor;
	else
		select false as Upou;
	end if;
end$$
    
create procedure AddPI(
	in _idServidor bigint,
    in _idUsuario bigint
) begin
	declare _codServidor int;
    declare _codUsuario int;
    set _codServidor = (select codigo_servidor from Servidores where id_servidor = _idServidor);
    if((select verificarConfig (_codServidor)) > 0 and (select PIConf from configuracoesservidores where cod_servidor = _codServidor)) then
		set _codUsuario = (select codigo_usuario from Usuarios where id_usuario = _idUsuario);
		call CriarPI(_codServidor, _codUsuario);
        update pontosinterativos set fragmentosPI = (fragmentosPI + 1) where servidores_usuarios_servidor = _codServidor and servidores_usuarios_usuario = _codUsuario;
        call LevelUP(_codServidor, _codUsuario);
	end if;
end$$

create function verificarCargo(
	_idCargo bigint,
    _codServidor bigint
) returns int begin
	declare _retorno int;
    set _retorno = (select count(cod) from Cargos where cod_Tipos_Cargos = 2 and id = _idCargo and codigo_Servidores = _codServidor);
    return _retorno;
end$$


create procedure AdicionarAtualizarCargoIP(
	in _cargo varchar(255),
    in _idCargo bigint,
    in _idServidor bigint,
    in _IPLevel bigint
) begin
	declare _codServidor int;
    set _codServidor = (select codigo_servidor from Servidores where id_servidor = _idServidor);
	if((select verificarCargos(_idCargo, _codServidor)) = 0 ) then
		insert into Cargos (cod_Tipos_Cargos, cargo, id, codigo_Servidores, requesito) values (2, _cargo, _idCargo, _codServidor, _IPLevel);
        select 1 as tipoOperacao;
	else
		update Cargos set requesito = _IPLevel where cod_Tipos_Cargos = 2 and id = _idCargo and codigo_Servidores = _codServidor;
        select 2 as tipoOperacao;
	end if;
end$$




#pitas

create procedure GetCh (
	in _tipo_canal bigint,
    in _id_servidor bigint
) begin 
	select Canais.cod, Canais.cod_Tipos_Canais, canal, id, servidores.id_servidor, Servidores.nome_servidor from Canais join servidores on Servidores.codigo_servidor = Canais.codigo_servidor where Canais.cod_Tipos_Canais = _tipo_canal and Canais.codigo_servidor = (Select Servidores.codigo_servidor from Servidores where Servidores.id_servidor = _id_servidor);
end$$

create procedure AdcCh (
	in _tipo_canal int,
	in _canal varchar (255),
    in _id_canal bigint,
    in _id_servidor bigint
) begin
	if(select count(Canais.cod) from Canais where Canais.id  = _id_canal and Canais.codigo_servidor = (select Servidores.codigo_Servidor from Servidores where Servidores.id_servidor = _id_servidor)) = 0 then
		insert into Canais (cod_Tipos_Canais, canal, id, codigo_servidor) values (_tipo_canal, _canal, _id_canal, (select Servidores.codigo_servidor from Servidores where Servidores.id_servidor = _id_servidor));
    end if;
end $$

delimiter ;

create table Tipos_Canais (
	cod bigint not null,
    Descricao varchar (255) not null unique,
    primary key (cod)
);

#Set dos canais yay
insert into Tipos_Canais values (0, "Bem Vindo (bemvindoCh)");
insert into Tipos_Canais values (1, "Sair (sairCh)");

create table Canais (
	cod bigint not null auto_increment,
    cod_Tipos_Canais bigint not null,
    canal varchar(255) not null,
    id bigint not null,
    codigo_servidor int not null,
    foreign key (cod_Tipos_Canais) references Tipos_Canais (cod),
    foreign key (codigo_servidor) references Servidores (codigo_servidor),
    primary key (cod)
);
