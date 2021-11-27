import BootstrapTable from "react-bootstrap-table-next";
import {Modal, Button, Form, Row, Col, FloatingLabel} from 'react-bootstrap'
import { useState, useEffect } from "react";

var offset = 0;
var filter = 'All'
var sortBy = 'ID'
var desc = 0

export default function Product() {
  const [productDescription, setproductDescription] = useState({id: -1})
  const [products, setProducts] = useState([]);
  // const [offset, setoffset] = useState(0);
  // const [filter, setFilter] = useState('All');
  // const [sortBy, setSortBy] = useState('ID');
  // const [desc, setDesc] = useState(0);
  
  const columns = [
    { dataField: "ID",            text: "Product ID",     sort: true },
    { dataField: "ProdName",      text: "Product Name",   sort: true },
    { dataField: "PriceIn",       text: "Import Price ",  sort: true },
    { dataField: "Price",         text: "Default Price",  sort: true },
    { dataField: "CurrentPrice",     text: "Current Price",  sort: true },
    { dataField: "Insurance",     text: "Insurance",      sort: true },
    { dataField: "TotalQuantity", text: "Total Quantity", sort: true }
  ];

  useEffect(() => {
    fetch("/api/product/all")
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

  const deleteProduct = function(id) {
    const index = products.findIndex((e => e.id === id))
    products.splice(index, 1)
    setProducts(products)
  }

  const rowEvents = {
    onClick: (e, row, rowIndex) => {
      setproductDescription(row)
    },
  };

  const loadData = function(reset = false) {
    offset = reset ? 0 : offset + 1
    fetch("/api/product/all?type="+filter+"&orderby="+sortBy+"&desc="+desc+"&offset="+offset)
    .then((response) => {
      if (response.ok) {
        return response.json()
      } 
      throw response
    })
    .then((data) => {
      setProducts(reset ? data : products.concat(data));
    })
    .catch((error) => {
      console.error("Error fetching data: ", error);
    })
  }

  const handleChangeFilter = function(event) {
    filter = event.target.value
    loadData(true)
  }

  const handleChangeSortBy = function(event) {
    sortBy = event.target.value
    loadData(true)
  }

  const handleChangeSort = function(event) {
    desc = event.target.value
    loadData(true)
  }

  function selectGroup() {
    return (
      <div>
        <Row className="g-2">
          <Col md>
            <FloatingLabel label="Filter">
              <Form.Select aria-label="Floating label select example" onChange={handleChangeFilter}>
                <option value='All'>All</option>
                <option value="Laptop">Laptop</option>
                <option value="Phone">Phone</option>
                <option value="Tablet">Tablet</option>
                <option value="Mouse">Mouse</option>
                <option value="HeadPhone">HeadPhone</option>
                <option value="OtherDevice">OtherDevice</option>
                <option value="OtherAccessory">OtherAccessory</option>
              </Form.Select>
            </FloatingLabel>
          </Col>
          <Col md>
            <FloatingLabel label="Sort by">
              <Form.Select aria-label="Floating label select example" onChange={handleChangeSortBy}>
                <option value="ID">ID</option>
                <option value="ProdName">Product Name</option>
                <option value="PriceIn">Import Price</option>
                <option value="Price">Default Price</option>
                <option value="CurrPrice">Current Price</option>
                <option value="Insurance">Insurance</option>
                <option value="TotalQuantity">Total Quantity</option>
              </Form.Select>
            </FloatingLabel>
          </Col>
          <Col md>
            <FloatingLabel label="Sort">
              <Form.Select aria-label="Floating label select example" onChange={handleChangeSort}>
                <option value="0">Ascending</option>
                <option value="1">Descending</option>
              </Form.Select>
            </FloatingLabel>
          </Col>
        </Row>
        {/* <Button variant="success" className="loadButton" onClick={() =>{loadData(true)}}>Load</Button> */}
      </div>
    )
  }

  return (
    <div className="popup_container">
      <div>
        {selectGroup()}
      </div>
      <div className="table-custom">
         {/* https://react-bootstrap-table.github.io/react-bootstrap-table2/docs/about.html  */}
        <BootstrapTable keyField="id" data={products} columns={columns} rowEvents={rowEvents}/>
      </div>
      <div className="container">
        <Button variant="success" onClick={() => {loadData(false)}}>Load More</Button>
      </div>
      <div>
        {productDescription.id === -1 ? <p/> : <ProductDescription id={productDescription.ID} 
          setproductDescription={setproductDescription} deleteProduct={deleteProduct} action={'Edit Product'}/>}
      </div>
    </div>
  );
}

function ProductDescription(props) {
  const {id, setproductDescription, deleteProduct, action} = props
  const [info, setInfo] = useState({})

  useEffect(() => {
    fetch("/api/product/info?id="+id)
    .then((response) => {
      if (response.ok) {
        return response.json()
      } 
      throw response
    })
    .then((data) => {setInfo(data)})
    .catch((error) => {
      console.error("Error fetching data: ", error);
    })
  }, [id])
  
  const handleSubmit = (event) => {
    event.preventDefault();
    console.log(event.target[0].value)
  }

  return(
    <div className="popup-background">
      <Modal.Dialog className="popup">
        <Modal.Header closeButton onClick={() => setproductDescription({id:-1})}>
          <Modal.Title>{action}</Modal.Title>
        </Modal.Header>

        <Modal.Body className="body-popup">
          <Form>
            {Object.keys(info).map( (k) => 
              <Form.Group className="mb-3" controlId="formBasicEmail">
                <Form.Label>{k}</Form.Label>
                <Form.Control type="ID" placeholder={"Enter " + k} defaultValue={info[k]}/>
              </Form.Group>
            )}
      
            <Button variant="primary" type="submit" onSubmit={handleSubmit}>
              Submit
            </Button>
          </Form>
        </Modal.Body>

        <Modal.Footer>
          <Button variant="danger" onClick={() => {deleteProduct(id); setproductDescription({id: -1})}}>Delete</Button>
          <Button variant="primary">Save changes</Button>
        </Modal.Footer>
      </Modal.Dialog>
    </div>
  )
}
