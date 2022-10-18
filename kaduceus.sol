//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 < 0.9.0;
//Coded by Rodrigo Alves Costa -> aka P1not

contract ServiceProvision {
    uint256 public companyCounter;
    uint256 public branchCounter;
    uint256 public employeeCounter;
    uint256 public serviceCounter;

    struct Company{
        string extCompanyCode;
        address companyWallet;
    }

    struct Branch{
        string extBranchCode;
        address branchWallet;
        address companyWallet;
    }

    struct Employee{
        string extEmployeeCode;
        address employeeWallet;
        address branchWallet;
        address companyWallet;
    }

    //sequence dos servi�os
    uint256 private sqService = 0;

    function getNextSqServiceId() private returns (uint256) {
        return ++sqService;
    }

    struct Service{
        uint256 serviceId;
        string extServiceCode;
        address employeeWallet;
        address branchWallet;
        address companyWallet;
        address customerWallet;
        string requestDate;
        string scheduledDate;
        string status;
        string obs;
        uint price;
        bool waitingPayment;
        string paidDate;
    }

    address private immutable owner;
 
    constructor() {
        owner = msg.sender;
    }

    mapping(address => Company) internal companys;
    mapping(address => Branch) internal branchs;
    mapping(address => Employee) internal employees;
    mapping(uint256 => Service) internal services;
    // Employee[] public employees;

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    modifier verificaPermissaoCancela(){
        require(msg.sender == owner);
        _;
    }

    //Only the owner can add a Company
    function addCompany(string calldata _extCompanyCode, address _companyWallet) external onlyOwner {
        //Verifica se o _companyWallet j� foi cadastrado em alguma outra estrutura        
        require(companys[_companyWallet].companyWallet != _companyWallet, "Company address already registered.");
        require(branchs[_companyWallet].branchWallet != _companyWallet, "Company address already registered as a branch.");
        require(employees[_companyWallet].employeeWallet != _companyWallet, "Company address already registered as an employee.");
        //require(services[_companyWallet].customerWallet != _companyWallet, "Company address already registered as a customer.");
        // companys[_companyWallet].push(Company(id, _extCompanyId, _extCompanyCode, _companyWallet, block.timestamp)); 
        companys[_companyWallet].extCompanyCode = _extCompanyCode;
        companys[_companyWallet].companyWallet = _companyWallet;
        companyCounter++;
    }

    //Only the Company can add a Branch
    function addBranch(string calldata _extBranchCode, address _branchWallet, address _companyWallet) external {
        //Verifica se o branch vai ser registrado para a companhia do sender
        require(msg.sender == _companyWallet, "The sender must be equal the company wallet");
        //Verifica se o sender � uma companhia
        require(companys[msg.sender].companyWallet == _companyWallet, "Only the company can add a branch.");
        //Verifica se o _branchWallet j� foi cadastrado em alguma estrutura
        require(companys[_branchWallet].companyWallet != _branchWallet, "Branch address already registered as a Company.");
        require(branchs[_branchWallet].branchWallet != _branchWallet, "Branch address already registered.");
        require(employees[_branchWallet].employeeWallet != _branchWallet, "Branch address already registered as an employee.");
        //require(services[_branchWallet].customerWallet != _branchWallet, "Branch address already registered as a customer.");
        //branchs[_branchWallet].branchId = getNextSqBranchId();
       // branchs[_branchWallet].extBranchId = _extBranchId;
        branchs[_branchWallet].extBranchCode = _extBranchCode;
        branchs[_branchWallet].branchWallet = _branchWallet;
        branchs[_branchWallet].companyWallet = _companyWallet;
        branchCounter++;
    }

    //Only a Branch can add an Employee
    function addEmployee(string memory _extEmployeeCode, address _employeeWallet, address _branchWallet, address _companyWallet) external {
        //Verifica se o empregado vai ser registrado para a filial do sender
        require(msg.sender == _branchWallet, "The sender must be equal the branch wallet.");
        //Verifica se o sender � uma filial
        require(branchs[msg.sender].branchWallet == _branchWallet, "Only a branch can add an employee.");
        //verifica se a companhia informada � a mesma da filial
        require(branchs[_employeeWallet].companyWallet != _companyWallet, "Branch address already registered as a Company."); 
        //Verifica se o _employeeWallet j� foi cadastrado em alguma estrutura
        require(companys[_employeeWallet].companyWallet != _branchWallet, "Branch address already registered as a Company.");
        require(branchs[_employeeWallet].branchWallet != _branchWallet, "Branch address already registered.");
        require(employees[_employeeWallet].employeeWallet != _branchWallet, "Branch address already registered as an employee.");
        //N�o verifico na de clientes pois a carteira de um cliente pode a vir a ser a de um funcion�rio um dia
        employees[_employeeWallet].extEmployeeCode = _extEmployeeCode;
        employees[_employeeWallet].employeeWallet = _employeeWallet;
        employees[_employeeWallet].branchWallet = _branchWallet;
        employees[_employeeWallet].companyWallet = _companyWallet;
        employeeCounter++;
    }

    //Obs.:external gasta menos q public, calldata gasta menos q memory
    
    //Only Employees can add a service for his branch
    function addService(string calldata _serviceCode, address _employeeWallet, address  _branchWallet, address _companyWallet, string calldata _requestDate, 
        string memory _scheduledDate, string memory _status, string memory _obs, uint _price)  external {    
        //verifica se � um empregado � o sender 
        require(msg.sender == _employeeWallet,  "The sender must be equal the employee wallet.");                
        //verifica se empregado pertence a filial informada 
        require(employees[_employeeWallet].branchWallet == _branchWallet,  "The employee is not part of the reported branch.");
        //verifica se a informada filial pertence a companhia informada
        require(branchs[_branchWallet].companyWallet == _companyWallet,  "The branch is not part of the reported company.");
        uint256 id = block.timestamp;
        services[id].serviceId = id;
        services[id].extServiceCode =_serviceCode;
        services[id].employeeWallet = _employeeWallet; 
        services[id].branchWallet = _branchWallet;
        services[id].companyWallet = _companyWallet;
        services[id].customerWallet = msg.sender;   //In this function, the sender will be always the customer
        services[id].requestDate = _requestDate; 
        services[id].scheduledDate = _scheduledDate; 
        services[id].status = _status; 
        services[id].obs = _obs;
        services[id].price = _price;    //msg.value;
        services[id].waitingPayment = false;
        serviceCounter++;
    }

    function updateService(Service memory _service) external {    

        //verifica se o sender � o empregado do servi�o - N�o pode alterar servi�os pagos
        if(msg.sender == services[_service.serviceId].employeeWallet) {
            //o funcionario informado tem que pertencer a branch do servi�o
            require(services[_service.serviceId].branchWallet == employees[_service.employeeWallet].branchWallet,  "The employee does not belong to the current branch in the service.");
            
            require(services[_service.serviceId].branchWallet == _service.branchWallet,  "Employers can't change the branch in a service.");

            require(services[_service.serviceId].companyWallet == _service.companyWallet,  "Employers can't change the company in a service."); 

            Service memory tmpSvc;

            //O que o funcion�rio pode atualizar:
            //(Atualizo s� o que mudou)
            if(!compareStrings(services[_service.serviceId].extServiceCode, _service.extServiceCode)){
                //services[_service.serviceId].extServiceCode = _service.extServiceCode;
                tmpSvc.extServiceCode =  _service.extServiceCode;
            }
            if(services[_service.serviceId].employeeWallet != _service.employeeWallet){
                //services[_service.serviceId].employeeWallet = _service.employeeWallet;
                tmpSvc.employeeWallet =  _service.employeeWallet;
            }
            if(!compareStrings(services[_service.serviceId].scheduledDate, _service.scheduledDate)){
                //services[_service.serviceId].scheduledDate = _service.scheduledDate;
                tmpSvc.scheduledDate =  _service.scheduledDate;
            }
            if(!compareStrings(services[_service.serviceId].status, _service.status)){
                //services[_service.serviceId].status = _service.status;
                tmpSvc.status = _service.status;
            }
            if(!compareStrings(services[_service.serviceId].obs, _service.obs)){
                //services[_service.serviceId].obs = _service.obs;
                tmpSvc.obs = _service.obs;
            }
            if(services[_service.serviceId].price != _service.price){
                // services[_service.serviceId].price = _service.price;
                tmpSvc.price = _service.price;
            }
            if(services[_service.serviceId].waitingPayment != _service.waitingPayment){
                // services[_service.serviceId].waitingPayment = _service.waitingPayment;
                tmpSvc.waitingPayment = _service.waitingPayment;
            }
            //if all data was validated and filled then update the service
            if(compareStrings(tmpSvc.extServiceCode, _service.extServiceCode) 
                && tmpSvc.employeeWallet ==  _service.employeeWallet
                && compareStrings(tmpSvc.scheduledDate, _service.scheduledDate)
                && compareStrings(tmpSvc.status, _service.status)
                && compareStrings(tmpSvc.obs, _service.obs) 
                && tmpSvc.price == _service.price
                && tmpSvc.waitingPayment == _service.waitingPayment){
                services[_service.serviceId].employeeWallet = tmpSvc.employeeWallet;
                services[_service.serviceId].scheduledDate = tmpSvc.scheduledDate;
                services[_service.serviceId].status = tmpSvc.status;
                services[_service.serviceId].obs = tmpSvc.obs;
                services[_service.serviceId].price = tmpSvc.price;
                services[_service.serviceId].waitingPayment = tmpSvc.waitingPayment;
                }           
        }

        //verifica se o sender � a branch do servi�o
        else if(msg.sender == services[_service.serviceId].branchWallet) {
            //verifico se o funcionario informado pertence a branch informada
            require(employees[_service.employeeWallet].branchWallet == _service.branchWallet,  "The informed employee must be part of the informed branch."); 
            //verifico se a companhia informada � a mesma do servi�o
            require(services[_service.serviceId].companyWallet == _service.companyWallet,  "Branchs can't change the company in a service."); 
            
            //O que  a branch pode atualizar:
            if(!compareStrings(services[_service.serviceId].extServiceCode, _service.extServiceCode)){
                 services[_service.serviceId].extServiceCode = _service.extServiceCode;
            }
            if(services[_service.serviceId].employeeWallet != _service.employeeWallet){                          
                services[_service.serviceId].employeeWallet = _service.employeeWallet;
            }
            if(services[_service.serviceId].branchWallet != _service.branchWallet){                          
                services[_service.serviceId].branchWallet = _service.branchWallet;
            }
            if(!compareStrings(services[_service.serviceId].scheduledDate, _service.scheduledDate)){
                 services[_service.serviceId].scheduledDate = _service.scheduledDate;
            }
            if(!compareStrings(services[_service.serviceId].status, _service.status)){
                 services[_service.serviceId].status = _service.status;
            }
            if(!compareStrings(services[_service.serviceId].obs, _service.obs)){
                 services[_service.serviceId].obs = _service.obs;
            }
            if(services[_service.serviceId].price != _service.price){
                services[_service.serviceId].price = _service.price;
            }
            //Se ainda n�o est� pago, posso alterar para o caso de pagamentos fiat
            if(services[_service.serviceId].waitingPayment != _service.waitingPayment 
               && compareStrings(services[_service.serviceId].paidDate, "0x")){  //verifica se = ''
                services[_service.serviceId].waitingPayment = _service.waitingPayment;
            }
            //s� posso considerar pago o que estava aguardando um pagamento.
            if(!compareStrings(services[_service.serviceId].paidDate, _service.paidDate)
                && compareStrings(services[_service.serviceId].paidDate, "0x")
                && services[_service.serviceId].waitingPayment){   
                 services[_service.serviceId].paidDate = _service.paidDate;
            }

            //Only if all received data were filled we can update the record 


        }
        //verifica se o sender � a company do servi�o
        else if(msg.sender == services[_service.serviceId].companyWallet) {
            services[_service.serviceId].extServiceCode =_service.extServiceCode;
            services[_service.serviceId].employeeWallet = _service.employeeWallet;
            services[_service.serviceId].branchWallet = _service.branchWallet;
            services[_service.serviceId].companyWallet = _service.companyWallet;  
            services[_service.serviceId].scheduledDate = _service.scheduledDate; 
            services[_service.serviceId].status = _service.status; 
            services[_service.serviceId].obs = _service.obs; 
            services[_service.serviceId].price = _service.price; 
            services[_service.serviceId].waitingPayment = _service.waitingPayment;
            services[_service.serviceId].paidDate = _service.paidDate;

        }
        //verifico se a companhia do funcionario informado � a mesma do cadastro desse funcionario 
        require(employees[_service.employeeWallet].companyWallet == _service.companyWallet,  "The informed employee must be part of the informed branch."); 

        //o sender tem q ser o empregado atual do servi�o, caso queira trocar para que outro realize o servi�o
        require(msg.sender == services[_service.serviceId].employeeWallet,  "The sender must be equal the actual employee of the service.");  
        //o endere�os tem que ser de um funcion�rio da filial e a filial deve pertencer a companhia a qual est� sendo prestado o servi�o    
        require(employees[_service.branchWallet].branchWallet == _service.branchWallet,  "The employee is not part of the reported branch.");
        require(branchs[_service.branchWallet].companyWallet == _service.companyWallet,  "The branch is not part of the reported company.");
        services[_service.serviceId].extServiceCode =_service.extServiceCode;
        services[_service.serviceId].employeeWallet = _service.employeeWallet; 
        services[_service.serviceId].branchWallet = _service.branchWallet;
        services[_service.serviceId].companyWallet = _service.companyWallet;
        services[_service.serviceId].scheduledDate = _service.scheduledDate; 
        services[_service.serviceId].status = _service.status; 
        services[_service.serviceId].obs = _service.obs;
        services[_service.serviceId].price = _service.price;    //msg.value
        services[_service.serviceId].waitingPayment = _service.waitingPayment;
        serviceCounter++;
    }

    function getCompany(address index) public view returns(Company memory){
        return companys[index];   
    }

    function getBranch(address index) public view returns(Branch memory){
        return branchs[index];   
    }

    function getEmployee(address index) public view returns(Employee memory){
        return employees[index];   
    }

    function getService(uint256 index) public view returns(Service memory){
        return services[index];   
    }

    function getTotEmployees() public view returns(uint){
           return employeeCounter;   
    }

    //Outra op��o � voc� fazer um for e comparar byte a byte da string, 
    //j� que a compara��o direta com sinais de igualdade n�o funciona com a string inteira.
    function compareStrings(string memory a, string memory b) private pure returns (bool)
    {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    //atualizar servi�o --> 
    //atualizar servi�o --> //cancela servi�o -->
    //private updateCompany S� o owner ou a pr�pria companhia podem atualizar o companycode
    //private updateBranch Se o sender for a branch ou a company, pode atualizar o branchcode
    //getBranchsByCompany   - chamado pela campanhia
    //getEmployeesByBranch
    //getEmployeesByCompany
    //removerFuncionario    - s� a carteira da filial ou da companhia podem remover um funcion�rio
    //removerBranch         - s� a carteira da companhia pode remover o branch
    //removerCompanhia      - s� o owner
    //reaberturaDeServi�o
    //estornoDePagamento

//       Opera��es do Sistema:
//  OK - AdicionarEmpresa
//  OK - AdicionarFilial
//  OK - AdicionarFuncionario
//     - RemoverEmpresa
//     - RemoverFilial
//     - RemoverFuncionario
//  OK - AgendarServi�o
//  OK - ConsultarServico
//  OK - AtualizarServico
//     - PagarEmpresa


//Proteger o sistema contra reentrancia

//o pagameno s� deve ser permitido apos autorizado pelo funcionario do servi�o.
//funcionarios s� podem alterar servi�os n�o pagos



    //para economizar,s� preciso atualizar os campos que sofreram altera��o
    // function editCustomer(uint32 id, Customer memory newCustomer) public {
    // Customer memory oldCustomer = customers[id];
    // if (bytes(oldCustomer.name).length == 0) return;
 
    // if (bytes(newCustomer.name).length > 0 && !compareStrings(oldCustomer.name, newCustomer.name))
    //     oldCustomer.name = newCustomer.name;
 
    // if (newCustomer.age > 0 && oldCustomer.age != newCustomer.age)
    //     oldCustomer.age = newCustomer.age;
 
    // customers[id] = oldCustomer;
    // }


//� melhor que o custo do AGENDAMENTO fique por conta da confirma��o do funcion�rio do que para o cliente. Leva a empresa a zelar pelo servi�o prestado.

//solicita��o de
// 1 - O agendamento � registrado pela wallet do funcionario quando ele confirma que poder� atender o servi�o
// 2 - Somente o cliente ou o funcionario do servi�o ou a companhia do servico podem Cancelar um servico agendado, pagando apenas a taxa de transacao da rede e evitando assim o abuso do servico
// 3 - O funcionario informado no Servico deve ser um funcionario da companhia do servico 




}


