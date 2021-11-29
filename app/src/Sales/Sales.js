import BootstrapTable from "react-bootstrap-table-next";
import {Modal, Button, Form, Row, Col, FloatingLabel} from 'react-bootstrap'
import { useState, useEffect } from "react";
import DatePicker, { registerLocale } from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";

var viewMode = 'Product';
var textBoxValue = '';

Date.prototype.yyyymmdd = function() {
  var mm = this.getMonth() + 1; // getMonth() is zero-based
  var dd = this.getDate();

  return [this.getFullYear(),
          (mm>9 ? '' : '0') + mm,
          (dd>9 ? '' : '0') + dd
         ].join('-');
};

export default function Sales() {
  const [productDescription, setSalesDescription] = useState({id: -1})
  const [products, setProducts] = useState([]);
  const [startDate, setStartDate] = useState(new Date());
  const [endDate, setEndDate] = useState(new Date());
  
  const columns = [
    { dataField: "ID",            text: "Sales ID",     sort: true },
    { dataField: "TimeStart",      text: "Start date",   sort: true },
    { dataField: "TimeEnd",       text: "End date ",  sort: true },
    { dataField: "PromoLevel",         text: "Rate",  sort: true },
    { dataField: "ProdID",         text: "Product ID",  sort: true },
    { dataField: "ProdName",         text: "Product name",  sort: true },
    { dataField: "manufacture",         text: "Brand",  sort: true }
  ];

  useEffect(() => {
    fetch("/api/sales/get/applied-products/all")
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
  return;
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
    fetch("/api/sales/get/applied-products/all")
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
    if (viewMode === "Product" && textBoxValue !== '')
    {
    fetch("/api/sales/get/product-sales?startDate=" + startDate.yyyymmdd() + "&endDate=" + endDate.yyyymmdd() + "&id=" + textBoxValue)
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
    else if (viewMode === "Brand" && textBoxValue !== ''){
    fetch("/api/sales/get/best-sales?startDate=" + startDate.yyyymmdd() + "&endDate=" + endDate.yyyymmdd() + "&brandName=" + textBoxValue)
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
    else{
    	fetch("/api/sales/get/applied-products/?startDate=" + startDate.yyyymmdd() + "&endDate=" + endDate.yyyymmdd())
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
  }
  
  const handleChangeText = function(event)
  {
  	textBoxValue = event.target.value;
  	loadSalesByDate();
  }
  
    const handleChangeDropBox = function(event) {
    viewMode = event.target.value;
    return;
  }
  
  function selectQueryOptions() {
    return (
      <div>
        <Row className="g-2">
        <Col>
            <FloatingLabel label="Filter by">
              <Form.Select aria-label="Floating label select example" onChange={handleChangeDropBox}>
                <option value="Product">Product</option>
                <option value="Brand">Brand</option>
              </Form.Select>
            </FloatingLabel>
        </Col>
	<Col>
            <FloatingLabel label="Filter">
		<Form.Control as="textarea" rows={1} onChange={handleChangeText}/>
            </FloatingLabel>
        </Col>
          <Col>
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
        <BootstrapTable keyField="id" data={products} columns={columns}/>
      </div>
      <div className="container">
        <Button variant="success" onClick={() => {loadSalesAll()}}>Load all</Button>
      </div>
    </div>
  );
}
