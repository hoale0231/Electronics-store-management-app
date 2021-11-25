import { BrowserRouter as Router, Route, Routes} from "react-router-dom";
import 'bootstrap/dist/css/bootstrap.min.css';
import './App.css';
import Product from './Product/Product'
import Dung from "./Dung/Dung";
import Toai from "./Toai/Toai";
import Tuan from "./Tuan/Tuan";
import Tu from "./Tu/Tu";
import {Navbar, Container, Nav} from 'react-bootstrap';


function NavBarHeader() {
  return (
    <Navbar bg="secondary" expand="lg">
      <Container>
        <Navbar.Brand href="/">Home</Navbar.Brand>
        <Navbar.Toggle aria-controls="basic-navbar-nav" />
        <Navbar.Collapse id="basic-navbar-nav">
          <Nav className="me-auto">
            <Nav.Link href="/Product">Product</Nav.Link>
            <Nav.Link href="/Dung">Dung</Nav.Link>
            <Nav.Link href="/Toai">Toai</Nav.Link>
            <Nav.Link href="/Tuan">Tuan</Nav.Link>
            <Nav.Link href="/Tu">Tu</Nav.Link>
          </Nav>
        </Navbar.Collapse>
      </Container>
    </Navbar>
  )
}

function App() {
  return (
    <div>
      <NavBarHeader/>
      <Router>
        <Routes>
          <Route path="/Product" element={<Product/>}/>
          <Route path="/Dung" element={<Dung/>}/>
          <Route path="/Toai" element={<Toai/>}/>
          <Route path="/Tuan" element={<Tuan/>}/>
          <Route path="/Tuan" element={<Tu/>}/>
        </Routes>
      </Router>
    </div>
  );
}


export default App;

