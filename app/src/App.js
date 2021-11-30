import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
import 'bootstrap/dist/css/bootstrap.min.css';
import './App.css';
import Product from './Product/Product'
import Sales from './Sales/Sales'
import SalesManagement from './Sales/SalesManagement'
import Order from "./Order/Order";
import Customer from "./Customer/Customer";
import Staff from "./Staff/Staff";
import Home from "./Home";
import { Navbar, Container, Nav, NavDropdown } from 'react-bootstrap';


function NavBarHeader() {
  return (
    <Navbar style={{ backgroundColor: "rgb(2, 80, 80)" }} expand="lg" fixed="top">
      <Container>
        <Navbar.Brand href="/">Home</Navbar.Brand>
        <Navbar.Toggle aria-controls="basic-navbar-nav" />
        <Navbar.Collapse id="basic-navbar-nav">
          <Nav className="me-auto">
            <Nav.Link href="/Product">Product</Nav.Link>
            <NavDropdown title="Sales" id="basic-nav-dropdown">
              <NavDropdown.Item href="/Sales">Sales</NavDropdown.Item>
              <NavDropdown.Item href="/SalesManagement">Sales Management</NavDropdown.Item>
            </NavDropdown>
            <Nav.Link href="/Order">Order</Nav.Link>
            <Nav.Link href="/Customer">Customer</Nav.Link>
            <Nav.Link href="/Staff">Staff</Nav.Link>
          </Nav>
        </Navbar.Collapse>
      </Container>
    </Navbar>
  )
}

function App() {
  return (
    <div>
      <NavBarHeader fixed="top" />
      <Router>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/Product" element={<Product />} />
          <Route path="/Sales" element={<Sales />} />
          <Route path="/SalesManagement" element={<SalesManagement />} />
          <Route path="/Order" element={<Order />} />
          <Route path="/Customer" element={<Customer />} />
          <Route path="/Staff" element={<Staff />} />
        </Routes>
      </Router>
    </div>
  );
}


export default App;

