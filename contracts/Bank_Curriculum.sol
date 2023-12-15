// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CurriculumBank {
    address public superiorAuthority;

    struct Experience {
        string title;
        string description;
        address verifyingAuthority;
        mapping(address => bool) validations;
        address superiorAuthority;
    }

    struct ExperienceInfo {
        string title;
        string description;
        address verifyingAuthority;
        address superiorAuthority;
        bool validationStatus;
    }

    struct VerifyingAuthority {
        string name;
        string acronym;
        uint256 totalCourses;
    }

    struct AuthorityInfo {
        string name;
        string acronym;
        address authorityAddress;
    }

    mapping(address => Experience[]) public courses;
    address[] public verifyingAuthoritiesList; 
    mapping(address => VerifyingAuthority) public verifyingAuthorities;
    mapping(address => bool) public isAuthorityAdded;

    event VerifyingAuthorityAdded(address indexed authority, string name, string acronym);
    event ExperienceCreated(address indexed course, uint256 indexed index, address verifyingAuthority);
    event CourseAuthorized(address indexed user, uint256 indexed courseIndex, address verifyingAuthority);

    /*
     * O criador do contrato será definido como a autorirado superior.
    */
    constructor() {
        superiorAuthority = msg.sender;
    }

    modifier onlySuperiorAuthority() {
        require(msg.sender == superiorAuthority, "Only the Superior Authority can execute this operation");
        _;
    }

    modifier onlyVerifyAuthority() {
        require(isAuthorityAdded[msg.sender], "Only a verify authority can execute this operation");
        _;
    }

    modifier onlyRegularUser() {
        require(!isAuthorityAdded[msg.sender] || msg.sender != superiorAuthority, "Only a regular user can execute this operation");
        _;
    }

    /************* Operações da Autoridade Superior *************/

    /*
     * Função para adicionar uma autoridade verificadora.
     * Restrição: Apenas a autoridade superior pode adicionar novas autoridades autorizadoras.
    */
    function addVerifyingAuthority(string memory name, string memory acronym, address authority) external onlySuperiorAuthority {
        require(!isAuthorityAdded[authority], "Already exists a verifying authority with this address");
        require(authority != address(0), "Invalid address");

        verifyingAuthorities[authority] = VerifyingAuthority(name, acronym, 0);
        verifyingAuthoritiesList.push(authority);
        isAuthorityAdded[authority] = true;

        emit VerifyingAuthorityAdded(authority, name, acronym);
    }

    /************* Operações da Autoridade Verificadora *************/

    /*
     * Função para criar um novo curso.
     * Restrição: Apenas a autoridade verificadora pode criar novos cursos.
    */
    function createCourse(string memory title, string memory description) external onlyVerifyAuthority {
        Experience storage newExperience = courses[msg.sender].push();
        newExperience.title = title;
        newExperience.description = description;
        newExperience.verifyingAuthority = msg.sender; 
        newExperience.superiorAuthority = superiorAuthority;

        newExperience.validations[msg.sender] = false;  

        emit ExperienceCreated(msg.sender, courses[msg.sender].length - 1, msg.sender);
    }
    /*
     * Função para validar um curso.
     * Restrição: Apenas a autoridade verificadora pode validar cursos.
    */
    function authorizeCourse(address user, uint256 courseIndex) external onlyVerifyAuthority {
        require(courseIndex < courses[user].length, "Invalid course index");

        courses[user][courseIndex].validations[msg.sender] = true;

        emit CourseAuthorized(user, courseIndex, msg.sender);
    }


    /************* Operações para usuarios regulares *************/

    /*
     * Função para um usuário adicionar um curso ao seu curriculo.
    */
    function addCourseToResume(uint256 courseIndex, address verifyingAuthority) external onlyRegularUser{
        require(isAuthorityAdded[verifyingAuthority], "Invalid verifying authority");
        require(courseIndex < courses[verifyingAuthority].length, "Invalid course index");

        Experience storage selectedCourse = courses[verifyingAuthority][courseIndex];

        Experience storage newExperience = courses[msg.sender].push();
        newExperience.title = selectedCourse.title;
        newExperience.description = selectedCourse.description;
        newExperience.verifyingAuthority = verifyingAuthority;  // Use a autoridade fornecida
        newExperience.superiorAuthority = superiorAuthority;

        newExperience.validations[msg.sender] = false;  

        emit ExperienceCreated(msg.sender, courses[msg.sender].length - 1, verifyingAuthority);
    }

    /************* Operações para usuarios regulares *************/

    /*
     * Função para verificar as autoridades verificadoras.
    */
    function getVerifyingAuthorities() external view returns (AuthorityInfo[] memory) {
        AuthorityInfo[] memory authorities = new AuthorityInfo[](verifyingAuthoritiesList.length);

        for (uint256 i = 0; i < verifyingAuthoritiesList.length; i++) {
            address authorityAddress = verifyingAuthoritiesList[i];
            authorities[i] = AuthorityInfo(
                verifyingAuthorities[authorityAddress].name,
                verifyingAuthorities[authorityAddress].acronym,
                authorityAddress
            );
        }

        return authorities;
    }

    function getSuperiorAuthority() external view returns (address) {
        return superiorAuthority;
    }


    /*
     * Função para buscar cursos de acordo com a autoridade verificadora.
    */
    function getCoursesByVerifyingAuthority(address authority) external view returns (ExperienceInfo[] memory) {
        require(isAuthorityAdded[authority], "Invalid verifying authority");

        Experience[] storage experiences = courses[authority];
        ExperienceInfo[] memory experienceInfos = new ExperienceInfo[](experiences.length);

        for (uint256 i = 0; i < experiences.length; i++) {
            experienceInfos[i] = ExperienceInfo({
                title: experiences[i].title,
                description: experiences[i].description,
                verifyingAuthority: experiences[i].verifyingAuthority,
                superiorAuthority: experiences[i].superiorAuthority,
                validationStatus: experiences[i].validations[authority]
            });
        }

        return experienceInfos;
    }
}
