//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 < 0.9.0;

/*Rules of the contract:
    1)Only the employee or the branch or the company in the service can change the EMPLOYEE in the service for another EMPLOYEE OF THE BRANCH AND COMPANY AND BRANCH OF THE SERVICE
    2)Only the branch or the company in the service can change the BRANCH in the service for another BRANCH OF THE COMPANY IN THE SERVICE 
    3)Only the company in the service can change the Company in the service for another COMPANY IN THIS CONTRACT 
    4)updateService can't be used if any value of the service has been paid
    5)refundedAmount will never be > amontPaid
    6)only the branch or the company of the service can refund the customer of the service
    7)only paid services can refund
    8)services with amountpaid !=0 can't me canceled -> rever! antes de cancelar tenho quer verificar em que momento é previsto o pagamento E a situação atual do pagamento
    //só pode pagar serviços aguardandoPagamento e não cancelado e serviço autorizado e refundedAmount = 0 e não totalmente pago e o valor totalPago + valor recebido no pagamento atual não pode ultrapassar o valor do serviço 
    //só pode aguardar pagamento serviços autorizados
    //só a branch do serviço pode autorizar o serviço
    5)O estorno será tratado em função separada
    O cancelamento será tratado em função separada
    ao lançar um reembolso, incrementa o valor pago no refundedAmount do serviço 
*/

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.7/contracts/utils/math/SafeMath.sol"; 

contract ServiceProvision {
    uint256 public companyCounter;
    uint256 public branchCounter;
    uint256 public employeeCounter;
    uint256 public serviceCounter;

    struct Company{
        string extCompanyCode;
        address payable companyWallet;
        string tokenName;
        bool useToke;
        bool payYields;
        uint256 payEveryXDays;
        bool branchsCanReceivePayment;
    }

    struct Branch{
        string extBranchCode;
        address payable branchWallet;
        address companyWallet;
        bool receivePayments;
    }

    struct Employee{
        string extEmployeeCode;
        address employeeWallet;
        address branchWallet;
        address companyWallet;
    }

    //sequence dos serviços
    uint256 private sqService = 0;

    function getNextSqServiceId() private returns (uint256) {
        return ++sqService;
    }

    //Os steps do atendimento do serviço serão controlados através de seus atributos 
    struct Service{
        uint256 serviceId;
        string extServiceCode;
        address employeeWallet;
        address branchWallet;
        address companyWallet;
        address customerWallet;
        string [] paidAfterBeforeExecution;
        string requestDate;
        string scheduledDate;
        bool autorizedForExecution;
        bool executed;       
        string status;
        string obs;
        uint price;
        bool waitingPayment;
        uint amontPaid;
        uint refundedAmount;
        bool fullyPaid;
        string payday;
        bool canceled;
    }

     struct Reimbursement{
        uint256 serviceId;  //have to reference a existing service
        uint value;
        address sender;
    }

    address payable private immutable owner;
    string contractToken = "MSYS";  //Will be used as reference for the airdrop of the balance of this contract
    uint256 payEveryXDays;

    constructor () { 
        owner = payable(msg.sender);
    } 

    mapping(address => address) internal authorizedUsers;
    mapping(address => Company) internal companys;
    mapping(address => Branch) internal branchs;
    mapping(address => Employee) internal employees;
    mapping(uint256 => Service) internal services;
    // Employee[] public employees;

    modifier onlyAuthorizedUsers(){
        require(msg.sender == authorizedUsers[msg.sender]);
        _;
    }

    // modifier verificaPermissaoCancela(){
    //     require(msg.sender == address);
    //     _;
    // }

    //Only the owner can add a Company
    function addCompany(string calldata _extCompanyCode, address _companyWallet) external onlyAuthorizedUsers {
        //Verifica se o _companyWallet já foi cadastrado em alguma outra estrutura        
        require(companys[_companyWallet].companyWallet != _companyWallet, "Company address already registered.");
        require(branchs[_companyWallet].branchWallet != _companyWallet, "Company address already registered as a branch.");
        require(employees[_companyWallet].employeeWallet != _companyWallet, "Company address already registered as an employee.");
        //require(services[_companyWallet].customerWallet != _companyWallet, "Company address already registered as a customer.");
        // companys[_companyWallet].push(Company(id, _extCompanyId, _extCompanyCode, _companyWallet, block.timestamp)); 
        companys[_companyWallet].extCompanyCode = _extCompanyCode;
        companys[_companyWallet].companyWallet = payable(_companyWallet);
        companyCounter++;
    }

    //Only the Company can add/update a Branch
    function addBranch(string calldata _extBranchCode, address _branchWallet, address _companyWallet) external {
        //Verifica se o branch vai ser registrado para a companhia do sender
        require(msg.sender == _companyWallet, "The sender must be equal the company wallet");
        //Verifica se o sender é uma companhia
        require(companys[msg.sender].companyWallet == _companyWallet, "Only the company can add a branch.");
        //Verifica se o _branchWallet já foi cadastrado em alguma estrutura
        require(companys[_branchWallet].companyWallet != _branchWallet, "Branch address already registered as a Company.");
        require(branchs[_branchWallet].branchWallet != _branchWallet, "Branch address already registered.");
        require(employees[_branchWallet].employeeWallet != _branchWallet, "Branch address already registered as an employee.");
        //require(services[_branchWallet].customerWallet != _branchWallet, "Branch address already registered as a customer.");
        //branchs[_branchWallet].branchId = getNextSqBranchId();
       // branchs[_branchWallet].extBranchId = _extBranchId;
        branchs[_branchWallet].extBranchCode = _extBranchCode;
        branchs[_branchWallet].branchWallet = payable(_branchWallet);
        branchs[_branchWallet].companyWallet = _companyWallet;
        branchCounter++;
    }

    //Only a Branch can add an Employee
    function addEmployee(string memory _extEmployeeCode, address _employeeWallet, address _branchWallet, address _companyWallet) external {
        //Verifica se o empregado vai ser registrado para a filial do sender
        require(msg.sender == _branchWallet, "The sender must be equal the branch wallet.");
        //Verifica se o sender é uma filial
        require(branchs[msg.sender].branchWallet == _branchWallet, "Only a branch can add an employee.");
        //verifica se a companhia informada é a mesma da filial
        require(branchs[_employeeWallet].companyWallet != _companyWallet, "Branch address already registered as a Company."); 
        //Verifica se o _employeeWallet já foi cadastrado em alguma estrutura
        require(companys[_employeeWallet].companyWallet != _branchWallet, "Branch address already registered as a Company.");
        require(branchs[_employeeWallet].branchWallet != _branchWallet, "Branch address already registered.");
        require(employees[_employeeWallet].employeeWallet != _branchWallet, "Branch address already registered as an employee.");
        //Não verifico na de clientes pois a carteira de um cliente pode a vir a ser a de um funcionário um dia
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
        //verifica se é um empregado é o sender 
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

        require(services[_service.serviceId].amontPaid != 0, "Can't update the service ultil it's fully paid or canceled.");

        //verifica se o sender é o empregado do serviço
        if(msg.sender == services[_service.serviceId].employeeWallet) {
            //o funcionario informado tem que pertencer a branch do serviço
            require(services[_service.serviceId].branchWallet == employees[_service.employeeWallet].branchWallet,  "The employee does not belong to the current branch in the service.");
            //verifica se a branch é 
            require(services[_service.serviceId].branchWallet == _service.branchWallet,  "Employers can't update the branch in a service.");

            require(services[_service.serviceId].companyWallet == _service.companyWallet,  "Employers can't change the company in a service."); 

            Service memory tmpSvc;

            //O que o funcionário pode atualizar:
            //(Atualizo só o que mudou)
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

        //verifica se o sender é a branch do serviço
        else if(msg.sender == services[_service.serviceId].branchWallet) {
            //verifico se o funcionario informado pertence a branch informada
            require(employees[_service.employeeWallet].branchWallet == _service.branchWallet,  "The informed employee must be part of the informed branch."); 
            //verifico se a companhia informada é a mesma do serviço
            require(services[_service.serviceId].companyWallet == _service.companyWallet,  "Branchs can't change the company in a service.");

            Service memory tmpSvc; 
            
            //O que  a branch pode atualizar:
            if(!compareStrings(services[_service.serviceId].extServiceCode, _service.extServiceCode)){
                //services[_service.serviceId].extServiceCode = _service.extServiceCode;
                tmpSvc.extServiceCode =  _service.extServiceCode;
            }
            if(services[_service.serviceId].employeeWallet != _service.employeeWallet){                          
                //services[_service.serviceId].employeeWallet = _service.employeeWallet;
                tmpSvc.extServiceCode =  _service.extServiceCode;
            }
            if(services[_service.serviceId].branchWallet != _service.branchWallet){                          
                // services[_service.serviceId].branchWallet = _service.branchWallet;
                tmpSvc.branchWallet =  _service.branchWallet;
            }
            if(!compareStrings(services[_service.serviceId].scheduledDate, _service.scheduledDate)){
                //  services[_service.serviceId].scheduledDate = _service.scheduledDate;
                 tmpSvc.scheduledDate =  _service.scheduledDate;
            }
            if(!compareStrings(services[_service.serviceId].status, _service.status)){
                // services[_service.serviceId].status = _service.status;
                tmpSvc.status =  _service.status;
            }
            if(!compareStrings(services[_service.serviceId].obs, _service.obs)){
                //  services[_service.serviceId].obs = _service.obs;
                tmpSvc.obs =  _service.obs;
            }
            if(services[_service.serviceId].price != _service.price){
                // services[_service.serviceId].price = _service.price;
                tmpSvc.price =  _service.price;
            }
            //Se ainda não está pago, posso alterar para o caso de pagamentos fiat
            if(services[_service.serviceId].waitingPayment != _service.waitingPayment 
               && compareStrings(services[_service.serviceId].payday, "0x")){  //verifica se = ''
                // services[_service.serviceId].waitingPayment = _service.waitingPayment;
                tmpSvc.waitingPayment =  _service.waitingPayment;

            }
            //só posso considerar pago o que estava aguardando um pagamento.
            if(!compareStrings(services[_service.serviceId].payday, _service.payday)
                && compareStrings(services[_service.serviceId].payday, "0x")
                && services[_service.serviceId].waitingPayment){   
                //  services[_service.serviceId].payday = _service.payday;
                tmpSvc.payday =  _service.payday;
            }

            //if all data was validated and filled then update the service
            if(compareStrings(tmpSvc.extServiceCode, _service.extServiceCode) 
                && tmpSvc.employeeWallet ==  _service.employeeWallet
                && tmpSvc.branchWallet == _service.branchWallet
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
        //verifica se o sender é a company do serviço
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
            services[_service.serviceId].payday = _service.payday;
        }
        //verifico se a companhia do funcionario informado é a mesma do cadastro desse funcionario 
        require(employees[_service.employeeWallet].companyWallet == _service.companyWallet,  "The informed employee must be part of the informed branch."); 
        //o sender tem q ser o empregado atual do serviço, caso queira trocar para que outro realize o serviço
        require(msg.sender == services[_service.serviceId].employeeWallet,  "The sender must be equal the actual employee of the service.");  
        //o endereços tem que ser de um funcionário da filial e a filial deve pertencer a companhia a qual está sendo prestado o serviço    
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

    function getCompany(address _index) public view returns(Company memory){
        return companys[_index];   
    }

    function getBranch(address _index) public view returns(Branch memory){
        return branchs[_index];   
    }

    function getEmployee(address _index) public view returns(Employee memory){
        return employees[_index];   
    }

    function getService(uint256 _index) public view returns(Service memory){
        return services[_index];   
    }

    function getTotEmployees() public view returns(uint){
           return employeeCounter;   
    }

    //Outra opção é você fazer um for e comparar byte a byte da string, 
    //já que a comparação direta com sinais de igualdade não funciona com a string inteira.
    function compareStrings(string memory a, string memory b) private pure returns (bool)
    {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }


    //Receive payments to create a company and so on
    function addAuthorizedUser(address _newUser) payable external {
        //verifica o valor pago para se cadastrar
        require(msg.value != 0.000750 ether,  "You have to pay 0.000750 ETH to be a new user.");    //   +- 1 USD in 20221018
        //Verifica se o usuário ja está cadastrado
        require(authorizedUsers[_newUser] == _newUser,  "User already registered."); 
        //Autoriza usuário
        authorizedUsers[_newUser] = _newUser;
        //this.balance[msg.sender] += msg.value;
    }

    function payService (Service calldata _service) external payable{
        //Verifica se o valor pago é o valor do serviço

        //
    }

    //atualizar serviço --> 
    //atualizar serviço --> //cancela serviço -->
    //private updateCompany Só o owner ou a própria companhia podem atualizar o companycode
    //private updateBranch Se o sender for a branch ou a company, pode atualizar o branchcode
    //getBranchsByCompany   - chamado pela campanhia
    //getEmployeesByBranch
    //getEmployeesByCompany
    //removerFuncionario    - só a carteira da filial ou da companhia podem remover um funcionário
    //removerBranch         - só a carteira da companhia pode remover o branch
    //removerCompanhia      - só o owner
    //reaberturaDeServiço
    //estornoDePagamento
    //cuponsdedesconto
    //dividendos




//       Operações do Sistema:
//  OK - AdicionarEmpresa
//  OK - AdicionarFilial
//  OK - AdicionarFuncionario
//     - RemoverEmpresa
//     - RemoverFilial
//     - RemoverFuncionario
//  OK - AgendarServiço
//  OK - ConsultarServico
//  OK - AtualizarServico
//     - pagarServiço
//  OK - pagarNovoUsuario
//     - 



//Proteger o sistema contra reentrancia

//o pagameno só deve ser permitido apos autorizado pelo funcionario do serviço.
//funcionarios só podem alterar serviços não pagos



    //para economizar,só preciso atualizar os campos que sofreram alteração
    // function editCustomer(uint32 id, Customer memory newCustomer) public {
    // Customer memory oldCustomer = customers[id];
    // if (bytes(oldCustomer.name).length == 0) return;
 
    // if (bytes(newCustomer.name).length > 0 && !compareStrings(oldCustomer.name, newCustomer.name))
    //     oldCustomer.name = newCustomer.name;
 
    // if (newCustomer.age > 0 && oldCustomer.age != newCustomer.age)
    //     oldCustomer.age = newCustomer.age;
 
    // customers[id] = oldCustomer;
    // }


//é melhor que o custo do AGENDAMENTO fique por conta da confirmação do funcionário do que para o cliente. Leva a empresa a zelar pelo serviço prestado.

//solicitação de
// 1 - O agendamento é registrado pela wallet do funcionario quando ele confirma que poderá atender o serviço
// 2 - Somente o cliente ou o funcionario do serviço ou a companhia do servico podem Cancelar um servico agendado, pagando apenas a taxa de transacao da rede e evitando assim o abuso do servico
// 3 - O funcionario informado no Servico deve ser um funcionario da companhia do servico 

//Será que é melhor cobrar a utilização do sistema 1 USD por wallet de funcionário cadastrado?

}


