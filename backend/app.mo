// Rural Banking Loan Application
import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Int "mo:base/Int";

actor RuralBankingApp {
  // Customer record
  type Customer = {
    id: Nat;
    name: Text;
    location: Text;
    contactNumber: Text;
    registrationDate: Time.Time;
  };

  // Loan record
  type Loan = {
    id: Nat;
    customerId: Nat;
    amount: Nat;
    interestRate: Float;
    startDate: Time.Time;
    durationMonths: Nat;
    status: Text; // "Active", "Completed", "Defaulted"
  };

  // Payment record
  type Payment = {
    id: Nat;
    loanId: Nat;
    amount: Nat;
    date: Time.Time;
  };

  // Storage
  private stable var nextCustomerId: Nat = 1;
  private stable var nextLoanId: Nat = 1;
  private stable var nextPaymentId: Nat = 1;

  private let customers = HashMap.HashMap<Nat, Customer>(10, Nat.equal, Int.hash);
  private let loans = HashMap.HashMap<Nat, Loan>(10, Nat.equal, Int.hash);
  private let payments = HashMap.HashMap<Nat, Payment>(50, Nat.equal, Int.hash);
  private let customerLoans = HashMap.HashMap<Nat, [Nat]>(10, Nat.equal, Int.hash);

  // Register a new customer
  public func registerCustomer(name: Text, location: Text, contactNumber: Text) : async Nat {
    let customerId = nextCustomerId;
    let customer: Customer = {
      id = customerId;
      name = name;
      location = location;
      contactNumber = contactNumber;
      registrationDate = Time.now();
    };
    
    customers.put(customerId, customer);
    nextCustomerId += 1;
    return customerId;
  };

  // Create a new loan for a customer
  public func createLoan(customerId: Nat, amount: Nat, interestRate: Float, durationMonths: Nat) : async ?Nat {
    switch (customers.get(customerId)) {
      case (null) { return null; };
      case (?customer) {
        let loanId = nextLoanId;
        let loan: Loan = {
          id = loanId;
          customerId = customerId;
          amount = amount;
          interestRate = interestRate;
          startDate = Time.now();
          durationMonths = durationMonths;
          status = "Active";
        };
        
        loans.put(loanId, loan);
        
        // Add loan to customer's loan list
        switch (customerLoans.get(customerId)) {
          case (null) { customerLoans.put(customerId, [loanId]); };
          case (?existingLoans) {
            let newLoans = Array.append<Nat>(existingLoans, [loanId]);
            customerLoans.put(customerId, newLoans);
          };
        };
        
        nextLoanId += 1;
        return ?loanId;
      };
    };
  };

  // Record a loan payment
  public func recordPayment(loanId: Nat, amount: Nat) : async Bool {
    switch (loans.get(loanId)) {
      case (null) { return false; };
      case (?loan) {
        if (loan.status != "Active") {
          return false;
        };
        
        let paymentId = nextPaymentId;
        let payment: Payment = {
          id = paymentId;
          loanId = loanId;
          amount = amount;
          date = Time.now();
        };
        
        payments.put(paymentId, payment);
        nextPaymentId += 1;
        
        // Check if loan is fully paid (simplified logic)
        // In a real application, you would calculate remaining balance
        return true;
      };
    };
  };

  // Get customer details
  public query func getCustomer(customerId: Nat) : async ?Customer {
    return customers.get(customerId);
  };

  // Get loan details
  public query func getLoan(loanId: Nat) : async ?Loan {
    return loans.get(loanId);
  };

  // Get all loans for a customer
  public query func getCustomerLoans(customerId: Nat) : async [?Loan] {
    switch (customerLoans.get(customerId)) {
      case (null) { return []; };
      case (?loanIds) {
        return Array.map<Nat, ?Loan>(
          loanIds, 
          func (id: Nat) : ?Loan { loans.get(id) }
        );
      };
    };
  };

  // Get all payments for a loan
  public query func getLoanPayments(loanId: Nat) : async [Payment] {
    var loanPayments: [Payment] = [];
    
    for ((id, payment) in payments.entries()) {
      if (payment.loanId == loanId) {
        loanPayments := Array.append(loanPayments, [payment]);
      };
    };
    
    return loanPayments;
  };
};
