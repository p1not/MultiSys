//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 < 0.9.0;
//Coded by P1not + Wesley

contract Detran {

    //motorista
    //agente de transito
    //funcionario detran

    struct FuncionarioDetran{
        address walletFuncionario;
    }

    struct Motorista {
        address walletMotorista;
        string registroNoSisDetran;
    }

    address owner;

    mapping(address => FuncionarioDetran) funcionariosDetran;
    mapping(address => Motorista) motoristas;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(owner == msg.sender, "Not allowed.");
        _;
    }

    function addFuncionarioDetran(address _newFuncionario) onlyOwner external {
        //Verifico se já está cadastrado
        require(_newFuncionario == funcionariosDetran[_newFuncionario].walletFuncionario, "Employee already registered.");
        funcionariosDetran[_newFuncionario].walletFuncionario = _newFuncionario;
    }

    function addMotorista(address _newMotorista) external {
        //Verifico se quem está chamando é um funcionario do Detran
        require(msg.sender == funcionariosDetran[msg.sender].walletFuncionario, "Nao e funcionario do Detran.");
        //Verifico se já está cadastrado
        require(_newMotorista == motoristas[_newMotorista].walletMotorista, "Employee already registered.");
        motoristas[_newMotorista].walletMotorista = _newMotorista;
    }

    function getFuncionario(address _walletFuncionario) external view returns(address) {
            return funcionariosDetran[_walletFuncionario].walletFuncionario;
    }

    
}
