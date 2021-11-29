import BootstrapTable from "react-bootstrap-table-next";
import {Button, Form, Row, Col, FloatingLabel, ButtonGroup} from 'react-bootstrap'
import { useState, useEffect } from "react";
import ProductDescription from "./ProductDescription";
import 'react-bootstrap-table2-filter/dist/react-bootstrap-table2-filter.min.css';
import filterFactory, { textFilter } from 'react-bootstrap-table2-filter';
import SummaryChart from "./chart";

var offset = 0;
var filter = 'All'
var sortBy = 'ID'
var desc = 0

export default function Product() {
  const [productDescription, setproductDescription] = useState(-1)
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([])
  const [series, setSeries] = useState([])

  const columns = [
    { dataField: "ID",            text: "Product ID",     filter: textFilter() }, 
    { dataField: "ProdName",      text: "Product Name",   filter: textFilter() }, 
    { dataField: "PriceIn",       text: "Import Price ",  filter: textFilter() }, 
    { dataField: "Price",         text: "Default Price",  filter: textFilter() }, 
    { dataField: "CurrentPrice",  text: "Current Price",  filter: textFilter() }, 
    { dataField: "TotalQuantity", text: "Total Quantity", filter: textFilter() }
  ];

  
  useEffect(() => {
    const getSummaryData = function() {
      fetch('/get/SummaryProduct')
      .then((response) => {
          if(response.ok) {
              return response.json()
          }
          throw response
      })
      .then((data) => {
          data.forEach(element => {
              var indexCategories = categories.findIndex(e => e === element["BranchName"])
              if (indexCategories === -1) {
                  categories.push(element["BranchName"])
                  indexCategories = categories.length - 1
              }
              var indexSeries = series.findIndex(e => e.name === element["DeviceType"])
              if (indexSeries === -1) {
                  series.push({name: element["DeviceType"], data: new Array(categories.length).fill(0)})
                  indexSeries = series.length - 1
              }
              const data = series[indexCategories].data
              while (indexCategories >= data.length) {
                  data.push(0)
              }
              series[indexSeries].data[indexCategories] = element["TotalProduct"]
          }); 
          setCategories(categories)
          setSeries(series)
        })
    }
    // Get Products Data
    fetch("/get/product")
    .then((response) => {
      if (response.ok) {
        return response.json()
      } else {
        response.text().then(text => { alert(text) })
      }
    })
    .then((data) => {setProducts(data); getSummaryData()})
    .catch((error) => {
      console.error("Error detect: ", error);
    }) 
    // Get Summary Data
    
  }, [categories, series])

  const deleteProduct = function(id) {
    const requestOptions = {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({ID: id})
    }
    fetch('/delete/product', requestOptions)
    .then((response) => {
      if (response.ok) {
        const index = products.findIndex((e => e.ID === id))
        products.splice(index, 1)
        setProducts(products)
        setproductDescription(-1)
      } else {
        response.text().then(text => { alert(text) })
      }
    })
    .catch((error) => {
      console.error("Error detect: ", error);
    })
  }

  const rowEvents = {
    onClick: (e, row, rowIndex) => {
      setproductDescription(row.ID)
    },
  };

  const loadData = function(reset = false, qty = 5) {
    offset = reset ? 0 : offset + 1
    fetch("/get/product?type="+filter+"&orderby="+sortBy+"&desc="+desc+"&offset="+offset+"&qty="+qty)
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
            <FloatingLabel label="Filter by product type">
              <Form.Select onChange={handleChangeFilter}>
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
              <Form.Select onChange={handleChangeSortBy}>
                <option value="ID">ID</option>
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
              <Form.Select onChange={handleChangeSort}>
                <option value="0">Ascending</option>
                <option value="1">Descending</option>
              </Form.Select>
            </FloatingLabel>
          </Col>
        </Row>
      </div>
    )
  }

  return (
    <div className="popup_container">
      <h1>Product summary</h1>
      <SummaryChart categories={categories} series={series}/>
      <h1>Product Table</h1>
      <div>
        {selectGroup()}
      </div>
      <Button className="customButton" variant="success" onClick={() => {setproductDescription(0)}}>Add product</Button>
      <div className="table-custom">
         {/* https://react-bootstrap-table.github.io/react-bootstrap-table2/docs/about.html  */}
        <BootstrapTable keyField="id" data={products} columns={columns} rowEvents={rowEvents} filter={filterFactory()}/>
      </div>
      <div className="container">
        <ButtonGroup className="me-2">
          <Button variant="success" onClick={() => {loadData(false)}}>Load More</Button>
        </ButtonGroup>
        <ButtonGroup className="me-2">
          <Button variant="success" onClick={() => {loadData(true, -1)}}>Load All</Button>
        </ButtonGroup>
      </div>
      <div>
        {productDescription === -1 ? <p/> : productDescription === 0 ? 
         <ProductDescription id={productDescription} setproductDescription={setproductDescription} action={'Add'}/> :
         <ProductDescription id={productDescription} setproductDescription={setproductDescription} deleteProduct={deleteProduct} action={'Edit'}/>}
      </div>
    </div>
  );
}

