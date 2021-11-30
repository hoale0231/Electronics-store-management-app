import BootstrapTable from "react-bootstrap-table-next";
import {Button, Form, Row, Col, FloatingLabel, ButtonGroup} from 'react-bootstrap'
import ProductDescription from "./ProductDescription";
import 'react-bootstrap-table2-filter/dist/react-bootstrap-table2-filter.min.css';
import filterFactory, { textFilter } from 'react-bootstrap-table2-filter';
import SummaryChart from "./chart";
import { Component } from "react";

var offset = 0;
var filter = 'All'
var sortBy = 'ID'
var desc = 0

export default class Product extends Component {
  constructor(props) {
    super(props);
    this.state = {
      productDescription: -1,
      products: [],
      categories: [],
      series: []
    }
    
    this.getProductData(true)
    this.handleChangeFilter = this.handleChangeFilter.bind(this)
    this.handleChangeSummary = this.handleChangeSummary.bind(this)
    this.handleChangeSort = this.handleChangeSort.bind(this)
    this.handleChangeSortBy = this.handleChangeSortBy.bind(this)
    this.setproductDescription = this.setproductDescription.bind(this)
    this.deleteProduct = this.deleteProduct.bind(this)
  }

  getSummaryData(ProdType) {
    fetch('/get/SummaryProduct?ProdType='+ProdType)
    .then((response) => {
        if(response.ok) {
            return response.json()
        } else {
          response.text().then(text => { alert(text);})
        }
    })
    .then((data) => {
      var categories = []
      var series = []
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
          const dataSeries = series[indexSeries].data
          while (indexCategories >= dataSeries.length) {
              dataSeries.push(0)
          }
          series[indexSeries].data[indexCategories] = element["TotalProduct"]
      }); 
      this.setState({
        categories: categories,
        series: series
      })
    })
  }

  getProductData(reset = false, qty = 5) {
    offset = reset ? 0 : offset + 1
    fetch("/get/product?type="+filter+"&orderby="+sortBy+"&desc="+desc+"&offset="+offset+"&qty="+qty)
    .then((response) => {
      if (response.ok) {
        return response.json()
      } else {
        response.text().then(text => { alert(text);})
      }
    })
    .then((data) => {
      this.setState({products: reset ? data : this.state.products.concat(data)})
      this.getSummaryData("All")
    })
    .catch((error) => {
      console.error("Error fetching data: ", error);
    })
  }

  deleteProduct(id) {
    const requestOptions = {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({ID: id})
    }
    fetch('/delete/product', requestOptions)
    .then((response) => {
      if (response.ok) {
        console.log("hello")
        this.setproductDescription(-1)
        const products = this.state.products
        const index = products.findIndex((e => e.ID === id))
        products.splice(index, 1)
        this.setState({
          products: products,
        })
      } else {
        response.text().then(text => { alert(text) })
      }
    })
    .catch((error) => {
      console.error("Error detect: ", error);
    })
  }

  rowEvents = {
    onClick: (e, row, rowIndex) => {
      this.setState({productDescription: row.ID})
    },
  };

  columns = [
    { dataField: "ID",            text: "Product ID",     filter: textFilter() }, 
    { dataField: "ProdName",      text: "Product Name",   filter: textFilter() }, 
    { dataField: "PriceIn",       text: "Import Price ",  filter: textFilter() }, 
    { dataField: "Price",         text: "Default Price",  filter: textFilter() }, 
    { dataField: "CurrentPrice",  text: "Current Price",  filter: textFilter() },
    { dataField: "Insurance",     text: "Insurance",      filter: textFilter() }, 
    { dataField: "TotalQuantity", text: "Total Quantity", filter: textFilter() }
  ];

  handleChangeFilter(event) {
    filter = event.target.value
    this.getProductData(true)
  }

  handleChangeSortBy(event) {
    sortBy = event.target.value
    this.getProductData(true)
  }

  handleChangeSort(event) {
    desc = event.target.value
    this.getProductData(true)
  }

  selectGroup() {
    return (
      <div>
        <Row className="g-2">
          <Col md>
            <FloatingLabel label="Filter by product type">
              <Form.Select onChange={this.handleChangeFilter}>
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
              <Form.Select onChange={this.handleChangeSortBy}>
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
              <Form.Select onChange={this.handleChangeSort}>
                <option value="0">Ascending</option>
                <option value="1">Descending</option>
              </Form.Select>
            </FloatingLabel>
          </Col>
        </Row>
      </div>
    )
  }

  handleChangeSummary(event) {
    this.getSummaryData(event.target.value)
  }
  
  setproductDescription(id) {
    this.setState({
      productDescription: id
    })
  }

  render() {
  return (
      <div className="popup_container">
        <h1>Product summary</h1>
          <FloatingLabel label="Filter by product type">
            <Form.Select onChange={this.handleChangeSummary}>
              <option value='All'>All</option>
              <option value="Laptop">Laptop</option>
              <option value="Phone">Phone</option>
              <option value="Tablet">Tablet</option>
              <option value="Mouse">Mouse</option>
              <option value="HeadPhone">HeadPhone</option>
              <option value="Device">Device</option>
              <option value="Accessory">Accessory</option>
              <option value="Other">Other</option>
            </Form.Select>
          </FloatingLabel>
          <SummaryChart categories={this.state.categories} series={this.state.series}/>
        <h1>Product Table</h1>
        <div>
          {this.selectGroup()}
        </div>
        <Button className="customButton" variant="success" onClick={() => {this.setproductDescription(0)}}>Add product</Button>
        <div className="table-custom">
            
        <BootstrapTable keyField="id" data={this.state.products} columns={this.columns} rowEvents={this.rowEvents} filter={filterFactory()}/>
        </div>
        <div className="container">
          <ButtonGroup className="me-2">
            <Button variant="success" onClick={() => {this.getProductData(false)}}>Load More</Button>
          </ButtonGroup>
          <ButtonGroup className="me-2">
            <Button variant="success" onClick={() => {this.getProductData(true, -1)}}>Load All</Button>
          </ButtonGroup>
        </div>
        <div>
          {this.state.productDescription === -1 ? <p/> : this.state.productDescription === 0 ? 
            <ProductDescription id={this.state.productDescription} setproductDescription={this.setproductDescription} action={'Add'}/> :
            <ProductDescription id={this.state.productDescription} setproductDescription={this.setproductDescription} deleteProduct={this.deleteProduct} action={'Edit'}/>}
        </div>
      </div>
    );
  }
}
