import BootstrapTable from "react-bootstrap-table-next";
import {Modal, Button, Form, Row, Col, FloatingLabel} from 'react-bootstrap'
import { useState, useEffect } from "react";
import DatePicker, { registerLocale } from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";

Date.prototype.yyyymmdd = function() {
  var mm = this.getMonth() + 1; // getMonth() is zero-based
  var dd = this.getDate();

  return [this.getFullYear(),
          (mm>9 ? '' : '0') + mm,
          (dd>9 ? '' : '0') + dd
         ].join('-');
};

export default function SalesManagement() {
  const [productDescription, setSalesDescription] = useState({id: -1})
  const [products, setProducts] = useState([]);
  const [startDate, setStartDate] = useState(new Date());
  const [endDate, setEndDate] = useState(new Date());
  
  const columns = [
    { dataField: "ID",            text: "Sales ID",     sort: true },
    { dataField: "TimeStart",      text: "Start date",   sort: true },
    { dataField: "TimeEnd",       text: "End date ",  sort: true },
    { dataField: "PromoLevel",         text: "Rate",  sort: true }
  ];

  useEffect(() => {
    fetch("/api/sales/get/sales-info/all")
    .then((response) => {
      if (response.ok) {
        return response.json()
      } 
      throw response
    })
    .then((data) => {setProducts(data);})
    .catch((error) => {
      console.error("Error fetching data: ", error);
    })
  }, [])

  const deleteSales = function(id) {
    const index = products.findIndex((e => e.ID === id))
    products.splice(index, 1);
     fetch("/api/sales/remove/sales?id=" + id)
    .then((response) => {
      if (response.ok) {
        return response.json()
      } 
      throw response
    })
    setProducts(products);
  }

  const rowEvents = {
    onClick: (e, row, rowIndex) => {
      setSalesDescription(row)
    },
  };

  const loadSalesAll = function() {
    fetch("/api/sales/get/sales-info/all")
    .then((response) => {
      if (response.ok) {
        return response.json()
      } 
      throw response
    })
    .then((data) => {
      setProducts(data);
    })
    .catch((error) => {
      console.error("Error fetching data: ", error);
    })
  }
  
    const loadSalesByDate = function() {
    fetch("/api/sales/get/sales-info-date?startDate=" + startDate.yyyymmdd() + "&endDate=" + endDate.yyyymmdd())
    .then((response) => {
      if (response.ok) {
        return response.json()
      } 
      throw response
    })
    .then((data) => {
      setProducts(data);
    })
    .catch((error) => {
      console.error("Error fetching data: ", error);
    })
  }
  
  function selectQueryOptions() {
    return (
      <div>
        <Row className="g-2">
          <Col xs="8">
          <FloatingLabel>
            <h6> Start date </h6>
            <DatePicker dateFormat="yyyy/MM/dd" selected={startDate} onChange={(date) => {setStartDate(date); loadSalesByDate()}} />
          </FloatingLabel>
          </Col>
          <Col>
          	<FloatingLabel>
            	<h6> End date </h6>
              <DatePicker dateFormat="yyyy/MM/dd" selected={endDate} onChange={(date) => {setEndDate(date); loadSalesByDate()}} />
              </FloatingLabel>
          </Col>
        </Row>
      </div>
    )
  }

  return (
    <div className="popup_container">
      <div>
        {selectQueryOptions()}
      </div>
      <div className="table-custom">
         {/* https://react-bootstrap-table.github.io/react-bootstrap-table2/docs/about.html  */}
        <BootstrapTable keyField="id" data={products} columns={columns} rowEvents={rowEvents}/>
      </div>
      <div className="container">
        <Button variant="success" onClick={() => {loadSalesAll()}}>Remove all filter</Button>
      </div>
      <div>
        {productDescription.id === -1 ? <p/> : <ProductDescription data={productDescription} 
          setSalesDescription={setSalesDescription} deleteSales={deleteSales} action={'Edit Product'}/>}
      </div>
    </div>
  );
}


function ProductDescription(props) {
  const {data, setSalesDescription, deleteSales, action} = props
  return(
    <div className="popup-background">
      <Modal.Dialog className="popup">
        <Modal.Header closeButton onClick={() => setSalesDescription({id:-1})}>
          <Modal.Title>{action}</Modal.Title>
        </Modal.Header>

        <Modal.Body>
          <Form>
            <Form.Group className="mb-3" controlId="formBasicEmail">
              <Form.Label>Product ID</Form.Label>
              <Form.Control type="ID" placeholder="Enter Product ID" />
            </Form.Group>

            <Form.Group className="mb-3" controlId="formBasicPassword">
              <Form.Label>Password</Form.Label>
              <Form.Control type="password" placeholder="Password" />
            </Form.Group>

            <Form.Group className="mb-3" controlId="formBasicCheckbox">
              <Form.Check type="checkbox" label="Check me out" />
            </Form.Group>
            
            <Button variant="primary" type="submit">
              Submit
            </Button>
          </Form>
        </Modal.Body>

        <Modal.Footer>
          <Button variant="danger" onClick={() => {deleteSales(data.ID); setSalesDescription({id: -1})}}>Delete</Button>
          <Button variant="primary">Save changes</Button>
        </Modal.Footer>
      </Modal.Dialog>
    </div>
  )
}
