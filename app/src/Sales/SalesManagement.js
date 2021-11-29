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
  var [addProduct, setAddProduct] = useState(0);
  
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
      <Row className="g-2">
      	<Col>
        	<Button variant="success" onClick={() => {loadSalesAll()}}>Load all</Button>
        </Col>
        <Col>
        	<Button variant="primary" onClick={() => {setAddProduct(1);}}>Add sales event</Button>
        </Col>
       </Row>
      </div>
      <div>
        {productDescription.id === -1 ? <p/> : <ProductDescription data={productDescription} 
          setSalesDescription={setSalesDescription} deleteSales={deleteSales} title={'Edit sales event'} action = 'edit' reload={loadSalesAll}/>}
      </div>
      <div>
        {addProduct === 0 ? <p/> : <NewProduct setAddProduct={setAddProduct} title={'Add sales event'} action = 'add' reload={loadSalesAll}/>}
      </div>
    </div>
  );
}


function ProductDescription(props) {
  const {data, setSalesDescription, deleteSales, title, action, reload} = props;
  var ID = data.ID;
  var editStartDate= new Date(data.TimeStart);
  var editEndDate = new Date(data.TimeEnd);
  var discountRate = data.PromoLevel;
  var applyType = "Product";
  var applyInfo = "";  
  
  const handleSubmit = (event) => {
     if (editStartDate > editEndDate) {
     alert("Start date must come before end date");       
     event.stopPropagation();
     event.preventDefault(); 
     return;
     }
     
     if (discountRate <= 0 || discountRate >= 100) {
     alert("Discount rate must be between 0 and 100"); 
     event.stopPropagation();
     event.preventDefault();
     return;
     }
  
      var query = "/api/sales/update/sales";
      fetch(query + "?id=" + ID + "&startDate=" + editStartDate.yyyymmdd() + "&endDate=" + editEndDate.yyyymmdd() + "&rate=" + discountRate)
      .then(response => {
        if (response.ok) {
          if (applyInfo !== "")
          {
          	console.log(applyInfo)
          	var applyQuery = applyType === "Product" ? "/api/sales/apply/product?productId=" : "/api/sales/apply/brand?brandName=";
          	fetch(applyQuery + applyInfo + "&salesId=" + ID)
      		.then(responseApply => {
        	if (responseApply.ok === false) {
          		responseApply.text().then(text => { alert(text); reload(); setSalesDescription({id: -1});})
        	   }
        	else{
        	        reload();
          		setSalesDescription({id: -1});
        	}
      		}) 
          }
          else
          {
          	reload();
          	setSalesDescription({id: -1});
          }

        } else {
          response.text().then(text => { alert(text) })
          event.stopPropagation();
        }
      }) 
    if (action === "edit") {
      event.preventDefault();
    }
  };
  
  return(
    <div className="popup-background">
      <Modal.Dialog className="popup">
        <Modal.Header closeButton onClick={() => setSalesDescription({id:-1})}>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>

        <Modal.Body>
          <Form onSubmit={handleSubmit}>
            <Form.Group className="mb-3" controlId="formSalesID">
              <Form.Label>Product ID</Form.Label>
              {action === 'edit'? <Form.Control type="ID" plaintext readOnly disabled defaultValue={data.ID}/> : <Form.Control type="ID" plaintext defaultValue="Enter sales ID"/>}
            </Form.Group>

            <Row className="mb-3">
		<Form.Group as={Col} controlId="formStartDate">
      			<Form.Label>Start date</Form.Label>
      			<Form.Control type="date" defaultValue={data.TimeStart} placeholder="Enter start date" onChange={(event) => {editStartDate = new Date(event.target.value)}}/>
    		</Form.Group>

    		<Form.Group as={Col} controlId="formEndDate">
      			<Form.Label>End date</Form.Label>
      			<Form.Control type="date" defaultValue={data.TimeEnd} placeholder="Enter end date" onChange={(event) => {editEndDate = new Date(event.target.value);}}/>
    		</Form.Group>
  	    </Row>
  	      <Form.Group className="mb-3" controlId="formDiscount">
    		<Form.Label>Discount rate</Form.Label>
    		<Form.Control type="text" defaultValue={data.PromoLevel} placeholder="Enter discount rate" onChange={(event) => {discountRate = event.target.value;}}/>
  	      </Form.Group>
  	      
  	      <Form.Group className="mb-3" controlId="formApplyType">
  	      <Form.Label>Apply for</Form.Label>
            <Form.Select aria-label="Floating label select example" onChange={(event) => {applyType = event.target.value;}}>
                <option value="Product">Product</option>
                <option value="Brand">Brand</option>
            </Form.Select>
            
            </Form.Group>
            <Form.Group className="mb-3" controlId="formProdId">
    		<Form.Label>Brand name/Product ID</Form.Label>
    		<Form.Control type="text" placeholder="Enter Brand name/Product ID" onChange={(event) => {applyInfo = event.target.value;}}/>
  	      </Form.Group>
          </Form>
        </Modal.Body>

        <Modal.Footer>
          <Button variant="danger" onClick={() => {deleteSales(data.ID); setSalesDescription({id: -1})}}>Delete</Button>
          <Button variant="primary" type="submit" onClick={handleSubmit}>Save changes</Button>
        </Modal.Footer>
      </Modal.Dialog>
    </div>
  )
}


function NewProduct(props) {
  const {setAddProduct, title, action, reload} = props;
  var ID = '';
  var editStartDate= null;
  var editEndDate = null;
  var discountRate = "0";
  var applyType = "Product";
  var applyInfo = "";  
  
  const handleSubmit = (event) => {
     if (ID ===  '')
     {
     	alert("Please enter an ID");       
     	event.stopPropagation();
     	event.preventDefault(); 
     	return;
     }
     
     if (ID.startsWith('KMSP') == false || ID.length !== 9)
     {
     	alert("ID must start with KMSP and has the length of 9");       
     	event.stopPropagation();
     	event.preventDefault(); 
     	return;
     }
     
     if (editStartDate == null || editEndDate == null)
     {
     	alert("Please enter start and end date");       
     	event.stopPropagation();
     	event.preventDefault(); 
     	return;
     }
  
     if (editStartDate > editEndDate) {
     alert("Start date must come before end date");       
     event.stopPropagation();
     event.preventDefault(); 
     return;
     }
     
     if (discountRate <= 0 || discountRate >= 100) {
     alert("Discount rate must be between 0 and 100"); 
     event.stopPropagation();
     event.preventDefault();
     return;
     }
  
      var query = "/api/sales/add/sales";
      fetch(query + "?id=" + ID + "&startDate=" + editStartDate.yyyymmdd() + "&endDate=" + editEndDate.yyyymmdd() + "&rate=" + discountRate)
      .then(response => {
        if (response.ok) {

          if (applyInfo !== "")
          {
          	var applyQuery = applyType === "Product" ? "/api/sales/apply/product?productId=" : "/api/sales/apply/brand?brandName=";
          	fetch(applyQuery + applyInfo + "&salesId=" + ID)
      		.then(responseApply => {
        	if (responseApply.ok === false) {
          		responseApply.text().then(text => { alert(text); reload(); setAddProduct(0);})
        	   }
        	else
        	{                 
        		reload();
          		setAddProduct(0);
        	}
      		}) 
          }
          else{
          reload();
          setAddProduct(0);
          }
        } else {
          response.text().then(text => { alert(text) })
          event.stopPropagation();
        }
      }) 
    if (action === "add") {
      event.preventDefault();
    }
  };
  
  return(
    <div className="popup-background">
      <Modal.Dialog className="popup">
        <Modal.Header closeButton onClick={() => setAddProduct(0)}>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>

        <Modal.Body>
          <Form onSubmit={handleSubmit}>
            <Form.Group className="mb-3" controlId="formSalesID">
              <Form.Label>Product ID</Form.Label>
              <Form.Control type="ID" type="text" placeholder="Enter sales ID" onChange = {(event) =>{ID = event.target.value;}}/>
            </Form.Group>

            <Row className="mb-3">
		<Form.Group as={Col} controlId="formStartDate">
      			<Form.Label>Start date</Form.Label>
      			<Form.Control type="date" placeholder="Enter start date" onChange={(event) => {editStartDate = new Date(event.target.value)}}/>
    		</Form.Group>

    		<Form.Group as={Col} controlId="formEndDate">
      			<Form.Label>End date</Form.Label>
      			<Form.Control type="date" placeholder="Enter end date" onChange={(event) => {editEndDate = new Date(event.target.value);}}/>
    		</Form.Group>
  	    </Row>
  	      <Form.Group className="mb-3" controlId="formDiscount">
    		<Form.Label>Discount rate</Form.Label>
    		<Form.Control type="text" placeholder="Enter discount rate" onChange={(event) => {discountRate = event.target.value;}}/>
  	      </Form.Group>
  	      
  	      <Form.Group className="mb-3" controlId="formApplyType">
  	      <Form.Label>Apply for</Form.Label>
            <Form.Select aria-label="Floating label select example" onChange={(event) => {applyType = event.target.value;}}>
                <option value="Product">Product</option>
                <option value="Brand">Brand</option>
            </Form.Select>
            
            </Form.Group>
            <Form.Group className="mb-3" controlId="formProdId">
    		<Form.Label>Brand name/Product ID</Form.Label>
    		<Form.Control type="text" placeholder="Enter Brand name/Product ID" onChange={(event) => {applyInfo = event.target.value;}}/>
  	      </Form.Group>
          </Form>
        </Modal.Body>

        <Modal.Footer>
          <Button variant="primary" type="submit" onClick={handleSubmit}>Save changes</Button>
        </Modal.Footer>
      </Modal.Dialog>
    </div>
  )
}
