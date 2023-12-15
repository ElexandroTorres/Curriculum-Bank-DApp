var contractAddress = "0x9Bad8D517fBB9e1Dfe9234EA5a5b8cb282385f9E";

document.addEventListener("DOMContentLoaded", onDocumentLoad);
function onDocumentLoad() {
  DApp.init();
  DApp.loadVerifyAuthoritiesList();
}

const DApp = {
  web3: null,
  contracts: {},
  account: null,
  accountType: null,

  init: function () {
    return DApp.initWeb3();
  },

  initWeb3: async function () {
    if (typeof window.ethereum !== "undefined") {
      try {
        const accounts = await window.ethereum.request({
          method: "eth_requestAccounts",
        });
        DApp.account = accounts[0];
        DApp.updateAccountType();
        window.ethereum.on('accountsChanged', DApp.updateAccount);
        console.log("Web3 connection successful.");
      } catch (error) {
        console.error("Error connecting to web3:", error.message);
        return;
      }
      DApp.web3 = new Web3(window.ethereum);
    } else {
      console.error("MetaMask not detected or installed.");
      return;
    }

    await DApp.initContract(); 
    DApp.updateAccountType(); 
    DApp.render();
  },

  updateAccount: async function() {
    DApp.account = (await DApp.web3.eth.getAccounts())[0];
    DApp.updateAccountType();
    DApp.render();
  },

  updateAccountType: async function() {
    const contract = DApp.contracts.CurriculumBankDapp;
    
    if (contract) {
      const superiorAuthority = await contract.methods.superiorAuthority(DApp.account).call();

      console.log("Account:", DApp.account);
      console.log("Superior Authority:", superiorAuthority);

      if (DApp.account === superiorAuthority) {
        DApp.accountType = "Superior Authority";
      } else if (await contract.methods.isAuthorityAdded(DApp.account).call()) {
        DApp.accountType = "Verifying Authority";
      } else {
        DApp.accountType = "Regular User";
      }

      console.log("Account Type:", DApp.accountType);
      DApp.render();
    }
    
  },

  initContract: async function () {
    DApp.contracts.CurriculumBankDapp = new DApp.web3.eth.Contract(abi, contractAddress);
  },

  render: function() {
    const accountTypeElement = document.getElementById("accountType");
    const mainContentElement = document.getElementById("mainContent");

    if (DApp.accountType === "Superior Authority") {
      accountTypeElement.innerHTML = "Entidade Superior";
      mainContentElement.innerHTML = `
        <h2>Lista de Entidades Autorizadoras</h2>
        <ul id="superiorAuthoritiesList"></ul>
        <button onclick="DApp.openAddVerifyAuthorityForm()">Adicionar Nova Entidade Autorizadora</button>
      `;
      DApp.loadVerifyAuthoritiesList();
    } else if (DApp.accountType === "Verifying Authority") {
      accountTypeElement.innerHTML = "Entidade Autorizadora";
      mainContentElement.innerHTML = "";
    } else {
      accountTypeElement.innerHTML = "Usuário Comum";
      mainContentElement.innerHTML = "";
    }
  },

  openAddVerifyAuthorityForm: function() {
    const mainContentElement = document.getElementById("mainContent");
    mainContentElement.innerHTML = `
      <h2>Adicionar Nova Entidade Autorizadora</h2>
      <form id="addverifyAuthorityForm" class="authority-form">
          <label for="name">Nome:</label>
          <input type="text" id="name" name="name" required><br>

          <label for="acronym">Sigla:</label>
          <input type="text" id="acronym" name="acronym" required><br>

          <label for="address">Endereço:</label>
          <input type="text" id="address" name="address" required><br>

          <button type="button" onclick="DApp.addVerifyAuthority()">Adicionar</button>
      </form>
    `;
},

  addVerifyAuthority: async function() {
    const name = document.getElementById("name").value;
    const acronym = document.getElementById("acronym").value;
    const address = document.getElementById("address").value;

    await DApp.contracts.CurriculumBankDapp.methods.addVerifyingAuthority(name, acronym, address).send({ from: DApp.account });

    DApp.render();
  },

  loadVerifyAuthoritiesList: async function() {
    const listElement = document.getElementById("verifyAuthoritiesList");
    listElement.innerHTML = "";

    const authorities = await DApp.contracts.CurriculumBankDapp.methods.getVerifyingAuthorities().call();

    if (authorities.length === 0) {
        const messageElement = document.createElement("p");
        messageElement.textContent = "Não existem autoridades verificadoras cadastradas.";
        listElement.appendChild(messageElement);
    } else {
        authorities.forEach(authority => {
            const listItem = document.createElement("li");
            listItem.textContent = `${authority.name} (${authority.acronym}) - ${authority.address}`;
            listElement.appendChild(listItem);
        });
    }
}

};
